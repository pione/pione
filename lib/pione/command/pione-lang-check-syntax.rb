module Pione
  module Command
    # `PioneLangCheckSyntax` is a command that checks syntax.
    class PioneLangCheckSyntax < BasicCommand
      #
      # informations
      #

      define(:name, "interactive")
      define(:desc, "Interactive environment for PIONE language")

      #
      # requirements
      #

      require "pp"

      #
      # options
      #

      option CommonOption.color

      option(:expr) do |item|
        item.type  = :string
        item.short = '-e'
        item.long  = '--expr'
        item.arg   = 'EXPR'
        item.desc  = 'PIONE expression'
      end

      option(:syntax) do |item|
        item.type  = :boolean
        item.short = '-s'
        item.long  = '--syntax'
        item.desc  = 'show syntax tree'
        item.init  = true
      end

      option(:model) do |item|
        item.type  = :boolean
        item.short = '-m'
        item.long  = '--model'
        item.desc  = 'show internal model'
        item.init  = false
      end

      option(:file) do |item|
        item.type  = :path
        item.short = '-f'
        item.long  = '--file'
        item.arg   = 'PATH'
        item.desc  = 'PIONE document that is checked'
      end

      option(:parser) do |item|
        item.type = :symbol
        item.long = '--parser'
        item.arg  = 'NAME'
        item.desc = 'Parser name'
        item.init = :expr
      end

      option_post(:source) do |item|
        item.process do
          test(not(model[:file]))
          test(not(model[:expr]))
          raise Rootage::OptionError.new(cmd, "Requires --file or --expr.")
        end
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << :source
      end

      setup(:source) do |item|
        item.desc = "Setup a source string"

        item.assign(:source) do
          test(model[:file])
          Pathname.new(model[:file]).read
        end

        item.assign(:source) do
          test(model[:expr])
          model[:expr]
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :make_syntax_tree
        seq << :print_syntax_tree
        seq << :make_internal_model
        seq << :print_internal_model
      end

      execution(:make_syntax_tree) do |item|
        item.desc = "Make a syntax tree"

        # parse
        item.assign(:stree) do
          Lang::DocumentParser.new.send(model[:parser]).parse(model[:source])
        end

        item.exception(Lang::ParserError, Parslet::ParseFailed) do |e|
          cmd.abort("Pione syntax error: %{reason}" % {reason: e.message})
        end
      end

      execution(:print_syntax_tree) do |item|
        item.desc = "Print the syntax tree"

        item.condition {test(model[:syntax])}

        item.process do
          puts "syntax:".color(:green)
          pp model[:stree]
        end
      end

      execution(:make_internal_model) do |item|
        item.desc = "Make an internal language model"

        item.condition {test(model[:model])}

        # make the internal model
        item.assign(:internal_model) do
          transformer_option = {}
          transformer_option[:package_name] = model[:package_name] || "PioneSyntaxChecker"
          transformer_option[:filename] = model[:filename] || "NoFile"

          Lang::DocumentTransformer.new.apply(model[:stree], transformer_option)
        end
      end

      execution(:print_internal_model) do |item|
        item.desc = "Print the internal language model"

        item.condition {test(model[:model])}

        # print model
        item.process do
          puts "model:".color(:green)
          pp model[:internal_model]
        end

        item.exception(Lang::LangTypeError, Lang::BindingError) do |e|
          cmd.abort("Pione model error: %{reason}" % {reason: e.message})
        end
      end
    end

    PioneLang.define_subcommand("check-syntax", PioneLangCheckSyntax)
  end
end
