module Pione
  module Command
    # `PioneLogListId` is a command that list IDs in PIONE raw log.
    class PioneLogListId < BasicCommand
      #
      # informations
      #

      define(:name, "list-id")
      define(:desc, "List log IDs")

      #
      # arguments
      #

      argument PioneLogArgument.log_location

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :list_id
      end

      execution(:list_id) do |item|
        item.desc = "List raw log IDs"

        item.process do
          raw_log_table = Log::XESLog.read(model[:log_location])
          raw_log_table.keys.each do |log_id|
            puts log_id
          end
        end
      end
    end

    PioneLog.define_subcommand("list-id", PioneLogListId)
  end
end

