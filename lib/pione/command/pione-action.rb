require 'pione/command/pione-action-exec'
require 'pione/command/pione-action-list'
require 'pione/command/pione-action-print'

module Pione
  module Command
    # PioneAction is a command definition of "pione action" for executing
    # literate action.
    class PioneAction < BasicCommand
      #
      # basic informations
      #

      command_name "pione action"
      command_banner "execute an action in literate action document"

      #
      # subcommands
      #

      define_subcommand("exec", PioneActionExec)
      define_subcommand("list", PioneActionList)
      define_subcommand("print", PioneActionPrint)
    end
  end
end
