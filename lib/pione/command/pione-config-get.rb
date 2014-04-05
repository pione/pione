module Pione
  module Command
    # `PioneConfigGet` is a command for getting a value of PIONE global
    # variable.
    class PioneConfigGet < BasicCommand
      #
      # basic informations
      #

      define(:name, "get")
      define(:desc, "Get a value of PIONE global variable")

      #
      # arguments
      #

      argument(:name) do |item|
        item.type = :string
        item.desc = "Variable name"
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
        item << :get
      end

      execution(:get) do |item|
        desc = "Get the value"

        item.process do
          puts model[:config].get(model[:name])
        end

        item.exception(Global::UnconfigurableVariableError) do |e|
          cmd.abort("'%s' is not a configurable item name." % model[:name])
        end
      end
    end

    PioneConfig.define_subcommand("get", PioneConfigGet)
  end
end
