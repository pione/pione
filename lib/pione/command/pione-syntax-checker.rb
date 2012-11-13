module Pione
  module Command
    class PioneSyntaxChecker < BasicCommand
      set_program_name("pione-syntax-checker")

      set_program_message <<TXT
Prints syntax tree of PIONE notation.
TXT

      define_option('-e', '--expr=expr', 'expression string') do |e|
        @expr = e
        @readline_mode = false
      end

      define_option('-t', '--transformer', 'show transformer result') do
        @transform = true
      end

      def initialize
        @readline_mode = true
      end

      def prepare
        require 'pp'
        @history = File.join(Global.dot_pione_dir, "pione-history")
        trap_int
      end

      def start
        if @readline_mode
          require 'readline'
          restore_history

          # start loop
          while buf = Readline.readline(Terminal.red("> "), true)
            if /[^\s]/.match(buf)
              # don't record if previous line is the same
              if Readline::HISTORY.size > 1 && Readline::HISTORY[-2] == buf
                Readline::HISTORY.pop
              end
              # print parsing result
              print_result(buf)
            else
              # don't record if it is an empty line
              Readline::HISTORY.pop
            end
          end
        else
          # print parsing result
          print_result(@expr)
        end
      end

      private

      # Prints parsing result of the string
      def print_result(str)
        begin
          puts Terminal.green("syntax:")
          stree = DocumentParser.new.parse(str).first
          pp stree
          if @transform
            puts Terminal.green("model:")
            pp DocumentTransformer.new.apply(stree)
          end
        rescue Pione::Parser::ParserError, Parslet::UnconsumedInput, Parslet::ParseFailed => e
          msg = "Pione syntax error: %s (%s)" % [e.message, e.class.name]
          @readline_mode ? puts(msg) : abort(msg)
        rescue Pione::Model::PioneModelTypeError,
          Pione::Model::VariableBindingError => e
          msg = "Pione model error: %s (%s)" % [e.message, e.class.name]
          @readline_mode ? puts(msg) : abort(msg)
        end
      end

      # Makes trap Ctr+C
      def trap_int
        trap("INT") do
          save_history
          exit
        end
      end

      # Restores history.
      def restore_history
        if File.exist?(@history)
          File.readlines(@history).reverse.each do |line|
            Readline::HISTORY.push line.chomp
          end
        end
      end

      # Saves history.
      def save_history
        File.open(@history, "w+") do |file|
          Readline::HISTORY.to_a.reverse[0..100].each do |line|
            file.puts(line) if /\S/.match(line)
          end
        end
      end
    end
  end
end
