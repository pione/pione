require 'pione/command/pione-package-add'
require 'pione/command/pione-package-build'
require 'pione/command/pione-package-show'
require 'pione/command/pione-package-update'

module Pione
  module Command
    # PionePackage is a subcommand that provides package utility tools.
    class PionePackage < BasicCommand
      #
      # basic informations
      #

      command_name "pione package"
      command_banner "PIONE package utility."

      define_subcommand "add"   , PionePackageAdd
      define_subcommand "build" , PionePackageBuild
      define_subcommand "show"  , PionePackageShow
      define_subcommand "update", PionePackageUpdate
    end
  end
end
