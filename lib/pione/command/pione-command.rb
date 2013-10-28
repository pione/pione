module Pione
  module Command
    # PioneCommand is a facade command for PIONE's various functions.
    class PioneCommand < BasicCommand
      # subcommand table
      @subcommand = {}

      class << self
        attr_reader :subcommand

        # Add the subcommand.
        def add_subcommand(name, command)
          @subcommand[name] = command
        end
      end

      #
      # basic informations
      #

      option_parser_mode :order!
      command_name "pione"
      command_banner "PIONE is a rule-based workflow engine."

      #
      # options
      #

      #
      # command lifecycle: execution phase
      #

      execute :subcommand

      def execute_subcommand
        name = @argv.first
        if cmd = self.class.subcommand[name]
          cmd.run(@argv.drop(1))
        else
          abort("no such subcommand: %s" % name)
        end
      end
    end
  end
end
