module Pione
  module Command
    # `PioneConfigSet` is a command for setting a value of PIONE global
    # variable.
    class PioneConfigSet < BasicCommand
      #
      # informations
      #

      define(:name, "set")
      define(:desc, "Set a value of PIONE global variable")

      #
      # arguments
      #

      argument(:name) do |item|
        item.type = :string
        item.desc = "variable name"
      end

      argument(:value) do |item|
        item.type = :string
        item.desc = "variable value"
      end

      #
      # options
      #

      option CommonOption.debug
      option PioneConfigOption.file

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << PioneConfigAction.load_config
        item << :set
        item << PioneConfigAction.save_config
      end

      execution(:set) do |item|
        item.desc = "Set the value"

        item.process do
          model[:config].set(model[:name], model[:value])
        end

        item.exception(Global::UnconfigurableVariableError) do |e|
          cmd.abort("'%s' is not a configurable item name." % cmd.name)
        end
      end
    end

    PioneConfig.define_subcommand("set", PioneConfigSet)
  end
end
