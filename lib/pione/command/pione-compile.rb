module Pione
  module Command
    # PioneCompile is a subcommand body of "pione compile".
    class PioneCompile < BasicCommand
      #
      # basic informations
      #

      define(:name, "pione compile")
      define(:desc, "translate from PNML to PIONE document")

      #
      # arguments
      #

      argument(:source) do |item|
        item.type = :location
        item.desc = "source PNML file"
      end

      #
      # options
      #

      option(CommonOption.debug)

      option(:flow_name) do |item|
        item.type = :string
        item.long = '--flow-name'
        item.arg  = 'NAME'
        item.desc = 'Set flow name'
      end

      option(:package_name) do |item|
        item.type = :string
        item.long = '--package-name'
        item.arg  = 'NAME'
        item.desc = 'Set package name'
      end

      option(:editor) do |item|
        item.type = :string
        item.long = '--editor'
        item.arg  = 'NAME'
        item.desc = 'Set package editor'
      end

      option(:tag) do |item|
        item.type = :string
        item.long = '--tag'
        item.arg  = 'NAME'
        item.desc = 'Set package tag'
      end

      option(:literate_action_document) do |item|
        item.type = :string
        item.long = '--action'
        item.arg  = 'LOCATION'
        item.desc = 'Set a literate action document'
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :literate_action
        item << :compile_pnml
        item << :print
      end

      execution(:literate_action) do |item|
        item.desc = "Parse a literate action document."

        item.assign(:literate_action) do
          if document = model[:literate_action_document]
            LiterateAction::MarkdownParser.parse(Location[document].read)
          end
        end
      end

      execution(:compile_pnml) do |item|
        item.desc = "Compile from PNML to PIONE"

        item.assign(:result) do
          net = PNML::Reader.read(model[:source])
          option = {
            :flow_name => model[:flow_name],
            :package_name => model[:package_name],
            :editor => model[:editor],
            :tag => model[:tag],
            :literate_actions => model[:literate_action]
          }
          PNML::Compiler.new(net, option).compile
        end
      end

      execution(:print) do |item|
        item.desc = "Print the PIONE document"

        item.process do
          print model[:result]
        end
      end
    end

    PioneCommand.define_subcommand("compile", PioneCompile)
  end
end
