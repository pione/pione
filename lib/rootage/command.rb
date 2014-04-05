module Rootage
  # CommandContext is a context used for action.
  class CommandContext < ProcessContext
    alias :cmd :scenario

    # Stop the item.
    def stop
      throw :rootage_stop_item, false
    end

    # quite the sequecen.
    def quit
      throw :rootage_quit_sequence, false
    end
  end

  # CommandPhase is a phase for command. Action items is this phase use CommandContext.
  class CommandPhase < Phase; end

  # Command is a scenario that has subcommands, options and arguments.
  class Command < Scenario
    define(:phase_class, CommandPhase)
    define(:process_context_class, CommandContext)

    # initial settings
    @subcommand = Hash.new
    @argument_definition = ArgumentDefinition.new
    @option_definition = OptionDefinition.new

    class << self
      attr_accessor :subcommand
      attr_accessor :argument_definition
      attr_accessor :option_definition

      def inherited(subclass)
        super

        subclass.subcommand = @subcommand.clone
        subclass.argument_definition = @argument_definition.copy
        subclass.option_definition = @option_definition.copy
      end

      forward :@argument_definition, :use     , :argument
      forward :@argument_definition, :pre     , :argument_pre
      forward :@argument_definition, :post    , :argument_post
      forward :@argument_definition, :append  , :append_argument
      forward :@argument_definition, :preppend, :preppend_argument
      forward :@argument_definition, :item    , :argument_item

      forward :@option_definition  , :use , :option
      forward :@option_definition  , :pre , :option_pre
      forward :@option_definition  , :post, :option_post
      forward :@option_definition  , :item, :option_item

      # Define an action to phase "init".
      def init(action, &b)
        define_action(:init, action, &b)
      end

      # Return true if the command is on toplevel.
      #
      # @return [Boolean]
      #   true if the command is on toplevel
      def toplevel?
        @info.has_key?(:toplevel) ? @info[:toplevel] : false
      end

      # Define a subcommand.
      #
      # @param name [String]
      #   subcommand name
      # @param subcommand [Class]
      #   subcommand class
      def define_subcommand(name, subcommand)
        @subcommand[name] = subcommand
      end

      # Return true if the command has subcommands.
      #
      # @return [Boolean]
      #   true if the command has subcommands
      def has_subcommands?
        not(@subcommand.values.compact.empty?)
      end
    end

    # initial phase
    define_phase(:init) do |seq|
      seq << InitAction.signal_trap
      seq << InitAction.option
      seq << InitAction.argument
      seq << InitAction.program_name
    end

    forward! :class, :subcommand, :has_subcommands?

    attr_reader :argv
    attr_reader :option_definition
    attr_reader :argument_definition

    def initialize(*args)
      super
      @argv = args[0].clone
      @parent_name = args[1]
      @argument_definition = self.class.argument_definition.copy
      @option_definition = self.class.option_definition.copy
    end

    def scenario_name
      if @parent_name
        "%s %s" % [@parent_name, super]
      else
        super
      end
    end
    alias :name :scenario_name

    def <<(object)
      case object
      when Argument
        argument_definition << object
      when Option
        option_definition << object
      else
        super
      end
    end

    # Run a lifecycle of the command.
    #
    # @return [void]
    def run
      load_requirements
      if has_subcommands?
        execute_subcommand
      end
      execute_phases
      exit
    end

    # Exit running command and return the status.
    def exit
      super
      Kernel.exit(exit_status)
    end

    def program_name
      scenario_name
    end

    private

    def enter_phase(phase_name)
      Timeout.timeout(phase(phase_name).config[:timeout]) do
        super
      end
    rescue PhaseTimeoutError => e
      abort(e)
    end

    # Execute subcommand.
    def execute_subcommand
      if subcommand_name = argv.first
        if subcommand.has_key?(subcommand_name)
          # run the subcommand
          return subcommand[subcommand_name].run(argv.drop(1), scenario_name)
        else
          unless subcommand_name[0] == "-"
            abort("There is no such subcommand: %{name}" % {name: subcommand_name})
          end
        end
      else
        abort('"%{name}" requires a subcommand name.' % {name: scenario_name})
      end
    end
  end

  # StandardCommand provides 4 phase command scenario. These phases are "init",
  # "setup", "execution", and "termination".
  class StandardCommand < Command
    # standard phases
    define_phase :setup
    define_phase :execution
    define_phase :termination

    class << self
      # Define an action to phase "setup".
      def setup(action, &b)
        define_action(:setup, action, &b)
      end

      # Define an action to phase "execution".
      def execution(action, &b)
        define_action(:execution, action, &b)
      end

      # Define an action to phase "termination".
      def termination(action, &b)
        define_action(:termination, action, &b)
      end
    end

    # Terminate the command. Note that this enters in termination phase first,
    # and command exit.
    def terminate
      enter_phase(:termination)
      self.exit # end with status code
    end

    private

    def abort_process
      unless current_phase == :termination
        enter_phase(:termination)
      end
    end
  end
end
