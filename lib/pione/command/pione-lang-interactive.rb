module Pione
  module Command
    # `PioneLangInteractive` is a command that provides interactive environment
    # for PIONE language.
    class PioneLangInteractive < BasicCommand
      #
      # informations
      #

      define(:name, "interactive")
      define(:desc, "Interactive environment for PIONE language")

      #
      # requirements
      #

      require "readline"

      #
      # arguments and options
      #

      option CommonOption.color

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << :load_history
      end

      setup(:load_history) do |item|
        item.desc = "Load history"

        item.assign(:history) do
          File.join(Global.dot_pione_dir, "pione-lang-interactive-history")
        end

        item.process do
          if File.exist?(model[:history])
            File.readlines(model[:history]).reverse.each do |line|
              Readline::HISTORY.push line.chomp
            end
          end
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :readline
      end

      execution(:readline) do |item|
        item.desc = "Start interactive environment"

        item.process do
          start_readline
        end
      end

      #
      # command lifecycle: termination phase
      #

      phase(:termination) do |item|
        item << :save_history
      end

      termination(:save_history) do |item|
        item.desc = "Save history file"

        item.process do
          File.open(model[:history], "w+") do |file|
            Readline::HISTORY.to_a.reverse[0..100].each do |line|
              file.puts(line) if /\S/.match(line)
            end
          end
        end
      end
    end

    PioneLang.define_subcommand("interactive" , PioneLangInteractive)

    class PioneLangInteractiveContext < Rootage::CommandContext
      def start_readline
        buf = ""
        mark = ">"

        # start loop
        while line = Readline.readline("#{mark} ".color(:red), true)
          buf += line
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
              print_result(Lang::DocumentParser.new.expr, buf)
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
      def print_result(parser, str)
        begin
          stree = parser.parse(str)
          transformer_option = {}
          transformer_option[:package_name] = model[:package_name] || "PioneSyntaxChecker"
          transformer_option[:filename] = model[:filename] || "NoFile"
          model = Lang::DocumentTransformer.new.apply(stree, transformer_option)
          if model.kind_of?(Array)
            model.each {|m| p m}
          else
            p model.eval(Lang::Environment.new)
          end
        rescue Lang::ParserError, Parslet::ParseFailed => e
          msg = "Pione syntax error: %s (%s)" % [e.message, e.class.name]
          puts(msg)
        rescue Lang::LangTypeError, Lang::BindingError => e
          msg = "Pione model error: %s (%s)" % [e.message, e.class.name]
          puts(msg)
        rescue Lang::MethodNotFound => e
          msg = "%s (%s)" % [e.message, e.class.name]
          puts(msg)
        end
      end
    end

    PioneLangInteractive.define(:process_context_class, PioneLangInteractiveContext)
  end
end
