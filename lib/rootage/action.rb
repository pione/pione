module Rootage
  # `Action` is an item for phase. This is a really rule, this means items
  # consist by conditions and action, so you can control firing and other
  # conditions.
  class Action < Item
    # Validator for the action item, command raises error if it is false.
    member :validator

    def validate(&b)
      self.validator = b
    end
  end

  # `Phase` is a sequence of action items.
  class Phase < Sequence
    set_item_class Action

    # @param [Action] the current executing action item
    member :current_action
    member :option, :default => lambda {Hash.new}

    def initialize(name=nil)
      super()
      self.name = name
    end

    # Execute all actions in this phase.
    #
    # @param scenario [Scenario]
    #   a scenario owned this phase
    # @return [void]
    def execute(scenario)
      err = PhaseTimeoutError.new(scenario.name, name)

      catch(:rootage_sequence_quit) do
        execute_pre(scenario)
        Timeout.timeout(option[:timeout], err) do
          execute_main(scenario) do |item|
            self.current_action = item
            err.action_name = item.name
          end
        end
        execute_post(scenario)
      end

      self.current_action = nil
    end
  end

  # `ActionCollection` is a collection of actions. Action collections should
  # extend this module.
  module ActionCollection
    include CollectionInterface
    set_item_class Action
  end

  # `InitAction` is a set of actions for PIONE commands initialization.
  module InitAction
    extend ActionCollection

    define(:signal_trap) do |item|
      item.desc = "Initialize signal trap actions"

      # explicit exit for signal INT (exit status code: failure)
      item.process do
        Signal.trap(:INT) do
          Signal.trap(:INT, "DEFAULT") # restore default trap
          cmd.abort('"%{name}" is terminated by signal INT.' % {name: cmd.name})
        end
      end

      # implicit abortion for signal TERM (exit status code: success)
      item.process do
        Signal.trap(:TERM) do
          Signal.trap(:TERM, "DEFAULT") # restore default trap
          Log.debug('"%{name}" is terminated by signal TERM.' % {name: cmd.name})
          cmd.terminate
        end
      end
    end

    define(:option) do |item|
      item.desc = "Initialize command options"

      item.process do
        cmd.option_definition.execute(cmd)
      end

      item.exception(OptionParser::ParseError, OptionError) do |e|
        cmd.abort(e)
      end
    end

    define(:argument) do |item|
      item.desc = "Initialize arguments"

      item.process do
        cmd.argument_definition.execute(cmd)
      end

      item.exception(ArgvError) do |e|
        cmd.abort(e)
      end
    end

    define(:program_name) do |item|
      item.desc = "Set the program name for `ps` command"

      item.process do
        $PROGRAM_NAME = cmd.program_name
      end
    end
  end
end
