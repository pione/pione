module Pione
  module Command
    # PionePackage is a command body of "pione-package".
    class PioneCompiler < BasicCommand
      #
      # basic informations
      #

      define(:name, "pione-compiler")
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

      option CommonOption.debug

      option(:name) do |item|
        item.type = :string
        item.long = '--name'
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

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :compile_pnml
        item << :print
      end

      execution(:compile_pnml) do |item|
        item.desc = "Compile from PNML to PIONE"

        item.assign(:result) do
          Util::PNMLCompiler.new(
            model[:source], model[:name], model[:editor], model[:tag]
          ).compile
        end
      end

      execution(:print) do |item|
        item.desc = "Print the PIONE document"

        item.process do
          print model[:result]
        end
      end
    end
  end
end
