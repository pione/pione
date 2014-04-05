module Pione
  module Command
    # PioneActionList is a command definition of "pione action:list" for listing
    # literate actions.
    class PioneActionList < BasicCommand
      #
      # basic informations
      #

      define(:name, "list")
      define(:desc, "List action names in document")

      #
      # arguments
      #

      argument(:location) do |item|
        item.type    = :location
        item.desc    = "Location of literate action document"
        item.missing = "There is no action document."
      end

      #
      # options
      #

      option CommonOption.color

      option(:compact) do |item|
        item.type    = :boolean
        item.long    = "--compact"
        item.desc    = "one-line list"
        item.default = false
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :get_names
        item << :show_list
      end

      execution(:get_names) do |item|
        item.desc = "Get all action names"

        item.assign(:names) do
          LiterateAction::Document.load(model[:location]).action_names.sort
        end

        item.process do
          test(model[:names].empty?)
          cmd.abort("There are no action names in %{location}" % {location: model[:location]})
        end
      end

      execution(:show_list) do |item|
        item.desc = "Show list of action names"

        item.process do
          if model[:compact]
            puts model[:names].join(" ")
          else
            model[:names].each {|name| puts name}
          end
        end
      end
    end

    PioneAction.define_subcommand("list", PioneActionList)
  end
end
