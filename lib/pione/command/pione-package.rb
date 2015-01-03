module Pione
  module Command
    # `PionePackage` is a subcommand that provides package utility tools.
    class PionePackage < BasicCommand
      #
      # informations
      #

      define(:name, "package")
      define(:desc, "PIONE package utility")

      #
      # requirements
      #

      require 'pione/command/pione-package-add'
      require 'pione/command/pione-package-build'
      require 'pione/command/pione-package-show'
      require 'pione/command/pione-package-update'
      require 'pione/command/pione-package-remove'
    end

    PioneCommand.define_subcommand("package", PionePackage)
  end
end
