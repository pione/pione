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

      define_option(:name) do |item|
        item.long = '--name=NAME'
        item.desc = 'set package name'
        item.value = proc {|val| val}
      end

      define_option(:editor) do |item|
        item.long = '--editor=NAME'
        item.desc = 'set package editor'
        item.value = proc {|val| val}
      end

      define_option(:tag) do |item|
        item.long = '--tag=NAME'
        item.desc = 'set package tag'
        item.value = proc {|val| val}
      end

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
        print Util::PNMLCompiler.new(Location[@source], option[:name], option[:editor], option[:tag]).compile
      end
    end
  end
end
