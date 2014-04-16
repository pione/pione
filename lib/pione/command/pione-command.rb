module Pione
  module Command
    # `PioneCommand` is a facade command for PIONE's various functions.
    class PioneCommand < BasicCommand
      #
      # basic informations
      #

      define(:toplevel, true)
      define(:name, "pione")
      define(:desc, "PIONE's utility command set")

      #
      # requirements
      #

      require 'pione/command/pione-action'
      require 'pione/command/pione-clean'
      require 'pione/command/pione-config'
      require 'pione/command/pione-diagnosis'
      require 'pione/command/pione-lang'
      require 'pione/command/pione-log'
      require 'pione/command/pione-package'
      require 'pione/command/pione-val'
      require 'pione/command/pione-compile'
    end
  end
end
