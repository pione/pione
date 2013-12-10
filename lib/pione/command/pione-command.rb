require 'pione/command/pione-action'
require 'pione/command/pione-clean'
require 'pione/command/pione-config'
require 'pione/command/pione-log'
require 'pione/command/pione-package'
require 'pione/command/pione-val'


module Pione
  module Command
    # PioneCommand is a facade command for PIONE's various functions.
    class PioneCommand < BasicCommand
      #
      # basic informations
      #

      option_parser_mode :order!
      toplevel true
      command_name "pione"
      command_banner "PIONE is a rule-based workflow engine."

      #
      # options
      #

      define_subcommand("action", PioneAction)
      define_subcommand("clean", PioneClean)
      define_subcommand("config", PioneConfig)
      define_subcommand("log", PioneLog)
      define_subcommand("package", PionePackage)
      define_subcommand("val", PioneVal)
    end
  end
end
