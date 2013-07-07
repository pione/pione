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
        use :color
        use :debug

        default :readline_mode, true

        define(:expr) do |item|
          item.short = '-e'
          item.long = '--expr=EXPR'
          item.desc = 'check the expression string and exit'
          item.action = lambda do |option, e|
            option[:expr] = e
            option[:readline_mode] = false
          end
        end

        define(:syntax) do |item|
          item.short = '-s'
          item.long = '--syntax'
          item.desc = 'show syntax tree'
          item.default = false
          item.value = true
        end

        define(:transform) do |item|
          item.short = '-t'
          item.long = '--transformer'
          item.desc = 'show transformer result'
          item.default = false
          item.value = true
        end

        define(:file) do |item|
          item.short = '-f'
          item.long = '--file=PATH'
          item.desc = 'check syntax of the document'
          item.action = lambda do |option, path|
            option[:document] = path
            option[:readline_mode] = false
          end
        end

        define :parser do |item|
          item.long = "--parser=NAME"
          item.desc = "set parser"
          item.value = lambda {|name| name}
        end
      end

      def initialize(*argv)
        super
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
          print_result(DocumentParser.new, Pathname.new(option[:document]).read)
        when :expr
          parser_name = option[:parser] ? option[:parser] : :expr
          print_result(DocumentParser.new.send(parser_name), option[:expr])
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
        while buf += Readline.readline("#{mark} ".color(:red), true)
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
              print_result(DocumentParser.new.expr, buf)
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
      def print_result(parser, str)
        begin
          stree = parser.parse(str)
          model = DocumentTransformer.new.apply(stree)
          if option[:syntax]
            puts "syntax:".color(:green)
            pp stree
          end
          if option[:transform]
            puts "model:".color(:green)
            pp model
          end
          if model.kind_of?(Array)
            model.each {|m| p m}
          else
            p model.eval(VariableTable.new)
          end
        rescue Pione::Parser::ParserError, Parslet::ParseFailed => e
          msg = "Pione syntax error: %s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        rescue Pione::Model::PioneModelTypeError,
          Pione::Model::VariableBindingError => e
          msg = "Pione model error: %s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        rescue Pione::Model::MethodNotFound => e
          msg = "%s (%s)" % [e.message, e.class.name]
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
