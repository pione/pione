module Pione
  module Command
    # `PioneConfig` is a utility set for PIONE global variables.
    class PioneConfig < BasicCommand
      #
      # informations
      #

      define(:name, "config")
      define(:desc, "Configure PIONE global variables")

      #
      # requirements
      #

      require 'pione/command/pione-config-get'
      require 'pione/command/pione-config-list'
      require 'pione/command/pione-config-set'
      require 'pione/command/pione-config-unset'
    end

    # `PioneConfigOption` is a set of common options for `pione config`
    # subcommands.
    module PioneConfigOption
      extend Rootage::OptionCollection

      define(:file) do |item|
        item.short = "-f"
        item.long = "--file"
        item.arg  = "PATH"
        item.desc = "path of config file"
        item.type = :path
        item.default = Global.config_path
      end
    end

    # `PioneConfigAction` is a set of common actions for `pione config`
    # subcommands.
    module PioneConfigAction
      extend Rootage::ActionCollection

      define(:load_config) do |item|
        item.desc = "Load PIONE configuration"

        item.assign(:config) do
          Global::Config.new(model[:file])
        end
      end

      define(:save_config) do |item|
        item.desc = "Save the configuration"

        item.process do
          model[:config].save(model[:file])
        end
      end
    end

    PioneCommand.define_subcommand("config", PioneConfig)
  end
end
