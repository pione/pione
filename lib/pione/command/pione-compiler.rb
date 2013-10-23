module Pione
  module Command
    # PionePackage is a command body of "pione-package".
    class PioneCompiler < BasicCommand
      #
      # basic informations
      #

      command_name "pione-compiler"
      command_banner "pione-compiler translates from PNML to PIONE document."

      #
      # options
      #

      use_option :debug

      #
      # command lifecycle: execution phase
      #

      setup :source

      def setup_source
        @source = @argv.first
      end

      #
      # command lifecycle: execution phase
      #

      execute :compile_to_pnml

      def execute_compile_to_pnml
        print Util::PNMLCompiler.new(Location[@source]).compile
      end
    end
  end
end
