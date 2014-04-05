module Pione
  module Command
    # `PioneVal` is a command that enables to get evaluation value of PIONE
    # expressions from out side of PIONE system.
    class PioneVal < BasicCommand
      #
      # informations
      #

      define(:name, "val")
      define(:desc, "Get the value of the PIONE expression")

      #
      # arguments
      #

      argument(:expr) do |item|
        item.type    = :string
        item.desc    = "PIONE expression string that is evaluated"
        item.missing = "There is no expression."
      end

      #
      # options
      #

      option CommonOption.debug
      option CommonOption.domain_dump_location

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |item|
        item << CommonAction.load_domain_dump
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :evaluation
        seq << :print
      end

      execution(:evaluation) do |item|
        item.desc = "Evaluate expression string as PIONE expression"

        item.assign(:val) do
          Pione.val(model[:expr], model[:domain_dump])
        end

        item.exception do |e|
          cmd.abort(e)
        end
      end

      execution(:print) do |item|
        item.desc = "Print the evaluation value"

        item.process do
          puts model[:val]
        end
      end
    end

    PioneCommand.define_subcommand("val", PioneVal)
  end
end
