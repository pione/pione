module Pione
  module Command
    # PioneSyntaxChecker is a command for checking syntax tree and model of the
    # PIONE document.
    class PioneSyntaxChecker < BasicCommand
      define_info do
        set_name "pione-syntax-checker"
        set_banner "Print syntax tree of PIONE notation."
      end

      define_option do
        default :readline_mode, true
        default :transform, false

        option('-e', '--expr=EXPR', 'check the expression string and exit') do |data, e|
          data[:expr] = e
          data[:readline_mode] = false
        end

        option('-t', '--transformer', 'show transformer result') do |data|
          data[:transform] = true
        end

        option('-f', '--file=PATH', 'check syntax of the document') do |data, path|
          data[:document] = path
          data[:readline_mode] = false
        end
      end

      def initialize
        @history = File.join(Global.dot_pione_dir, "pione-history")
      end

      prepare do
        require 'pp'
      end

      start do
        case action_mode
        when :readline
          action_readline_mode
        when :file
          print_result(Pathname.new(option[:document]).read)
        when :expr
          print_result(option[:expr])
        end
      end

      terminate(:pre) do
        save_history if readline_mode?
      end

      private

      # Return action mode.
      #
      # @return [Symbol]
      #   action mode
      def action_mode
        return :readline if readline_mode?
        return :file if option[:document]
        return :expr if option[:expr]
      end

      # Return true if readline mode is enabled.
      #
      # @return [Boolean]
      #   true if readline mode is enabled
      def readline_mode?
        option[:readline_mode]
      end

      # Action readline mode.
      #
      # @return [void]
      def action_readline_mode
        require 'readline'
        restore_history
        buf = ""
        mark = ">"

        # start loop
        while buf += Readline.readline(Terminal.red("#{mark} "), true)
          if /[^\s]/.match(buf)
            # don't record if previous line is the same
            if Readline::HISTORY.size > 1 && Readline::HISTORY[-2] == buf
              Readline::HISTORY.pop
            end
            if buf[-1] == "\\"
              buf[-1] = "\n"
              mark = "+"
              next
            else
              # print parsing result
              puts buf
              print_result(buf)
              buf = ""
              mark = ">"
            end
          else
            # don't record if it is an empty line
            Readline::HISTORY.pop
          end
        end
      end

      # Print parsing result of the string.
      #
      # @param str [String]
      #   PIONE expression
      # @return [void]
      def print_result(str)
        begin
          puts Terminal.green("syntax:")
          stree = DocumentParser.new.parse(str)
          pp stree
          if option[:transform]
            puts Terminal.green("model:")
            pp DocumentTransformer.new.apply(stree)
          end
        rescue Pione::Parser::ParserError, Parslet::ParseFailed => e
          msg = "Pione syntax error: %s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        rescue Pione::Model::PioneModelTypeError,
          Pione::Model::VariableBindingError => e
          msg = "Pione model error: %s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        end
      end

      # Restore readline's history.
      #
      # @return [void]
      def restore_history
        if File.exist?(@history)
          File.readlines(@history).reverse.each do |line|
            Readline::HISTORY.push line.chomp
          end
        end
      end

      # Save history to file.
      #
      # @return [void]
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
