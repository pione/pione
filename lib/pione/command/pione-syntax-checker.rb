module Pione
  module Command
    # PioneSyntaxChecker is a command for checking syntax tree and model of the
    # PIONE document.
    class PioneSyntaxChecker < BasicCommand
      #
      # basic informations
      #

      command_name "pione-syntax-checker"
      command_banner "Print syntax tree of PIONE notation."

      #
      # options
      #

      use_option :color
      use_option :debug

      option_default(:readline_mode, true)

      define_option(:expr) do |item|
        item.short = '-e'
        item.long = '--expr=EXPR'
        item.desc = 'check the expression string and exit'
        item.action = lambda do |_, option, e|
          option[:expr] = e
          option[:readline_mode] = false
        end
      end

      define_option(:syntax) do |item|
        item.short = '-s'
        item.long = '--syntax'
        item.desc = 'show syntax tree'
        item.default = false
        item.value = true
      end

      define_option(:transform) do |item|
        item.short = '-t'
        item.long = '--transformer'
        item.desc = 'show transformer result'
        item.default = false
        item.value = true
      end

      define_option(:file) do |item|
        item.short = '-f'
        item.long = '--file=PATH'
        item.desc = 'check syntax of the document'
        item.action = lambda do |_, option, path|
          option[:document] = path
          option[:readline_mode] = false
        end
      end

      define_option(:parser) do |item|
        item.long = "--parser=NAME"
        item.desc = "set parser"
        item.value = lambda {|name| name}
      end

      #
      # instance methods
      #

      def initialize(*argv)
        super
        @history = File.join(Global.dot_pione_dir, "pione-history")
      end

      #
      # command lifecycle: setup phase
      #

      setup :pp
      setup :readline => :readline_mode

      def setup_pp
        require 'pp'
      end

      def setup_readline_mode
        require 'readline'
        restore_history
      end

      #
      # command lifecycle: execute phase
      #

      execute :readline => :readline_mode
      execute :file => :file
      execute :expr => :expr

      def execute_readline_mode
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

      def execute_file
        print_result(DocumentParser.new, Pathname.new(option[:document]).read)
      end

      def execute_expr
        parser_name = option[:parser] ? option[:parser] : :expr
        print_result(DocumentParser.new.send(parser_name), option[:expr])
      end

      #
      # command lifecycle: termination phase
      #

      terminate :readline => :history

      def terminate_history
        save_history if readline_mode?
      end

      #
      # helper methods
      #

      private

      # Return action mode.
      def action_mode
        return :readline if readline_mode?
        return :file if option[:document]
        return :expr if option[:expr]
      end

      # Return true if readline mode is enabled.
      def readline_mode?
        option[:readline_mode]
      end

      # Print parsing result of the string.
      def print_result(parser, str)
        begin
          stree = parser.parse(str)
          transformer_option = {}
          transformer_option[:package_name] = option[:package_name] || "PioneSyntaxChecker"
          transformer_option[:filename] = option[:filename] || "NoFile"
          model = DocumentTransformer.new.apply(stree, transformer_option)
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
            p model.eval(Lang::Environment.new)
          end
        rescue Parser::ParserError, Parslet::ParseFailed => e
          msg = "Pione syntax error: %s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        rescue Lang::PioneTypeError, Lang::VariableBindingError => e
          msg = "Pione model error: %s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        rescue Lang::MethodNotFound => e
          msg = "%s (%s)" % [e.message, e.class.name]
          readline_mode? ? puts(msg) : abort(msg)
        end
      end

      # Restore readline's history.
      def restore_history
        if File.exist?(@history)
          File.readlines(@history).reverse.each do |line|
            Readline::HISTORY.push line.chomp
          end
        end
      end

      # Save history to file.
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
