module Pione
  module Command
    # PioneAction is a command definition of "pione action" for executing
    # literate action.
    class PioneAction < BasicCommand
      #
      # basic informations
      #

      define(:name, "action")
      define(:desc, "execute an action in literate action document")

      #
      # subcommands
      #

      require 'pione/command/pione-action-exec'
      require 'pione/command/pione-action-list'
      require 'pione/command/pione-action-print'
    end

    PioneCommand.define_subcommand("action", PioneAction)
  end
end
