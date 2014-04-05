module Pione
  module Command
    # `PioneConfigUnset` is a command for unsetting a value of PIONE global
    # variable.
    class PioneConfigUnset < BasicCommand
      #
      # informations
      #

      define(:name, "unset")
      define(:desc, "Unset a value of PIONE global variable")

      #
      # arguments
      #

      argument(:name) do |item|
        item.type = :string
        item.desc = "variable name"
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
        item << :unset
        item << PioneConfigAction.save_config
      end

      execution(:unset) do |item|
        item.desc = "Unset the item"

        item.process do
          model[:config].unset(model[:name])
        end
      end
    end

    PioneConfig.define_subcommand("unset", PioneConfigUnset)
  end
end
