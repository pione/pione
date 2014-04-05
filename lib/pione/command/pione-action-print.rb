module Pione
  module Command
    # `PioneActionPrint` is a command that prints action contents.
    class PioneActionPrint < BasicCommand
      #
      # basic informations
      #

      define(:name, "print")
      define(:desc, "Print action contents")

      #
      # arguments
      #

      argument(:location) do |item|
        item.type    = :location
        item.missing = "There are no action documents or packages."
      end

      argument(:name) do |item|
        item.type    = :string
        item.missing = "There is no action name."
      end

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug
      option CommonOption.domain_dump_location

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << CommonAction.load_domain_dump
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :find_action
        seq << :print
      end

      execution(:find_action) do |item|
        item.desc = "Find the action from the document"

        item.assign(:action) do
          LiterateAction::Document.load(model[:location]).find(model[:name])
        end

        item.process do
          test(not(model[:action]))
          cmd.abort("Action not found.")
        end

        item.exception(Location::NotFound) do |e|
          cmd.abort(e)
        end
      end

      execution(:print) do |item|
        item.desc = "Print the action contents"

        item.process do
          puts model[:action].textize(model[:domain_dump])
        end
      end
    end

    PioneAction.define_subcommand("print", PioneActionPrint)
  end
end
