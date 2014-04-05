module Pione
  module Command
    # `PionePackageUpdate` is a subcommand that updates PIONE package.
    class PionePackageUpdate < BasicCommand
      #
      # informations
      #

      define(:name, "update")
      define(:desc, "Update the package to package database")

      #
      # arguments
      #

      argument(:location) do |item|
        item.type    = :location
        item.desc    = "the package location that you want to update"
        item.missing = "There are no PIONE documents or packages."
      end

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug

      option(:force) do |item|
        item.type    = :boolean
        item.long    = "--force"
        item.desc    = "update pacakge info files"
        item.default = true
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :update
      end

      execution(:update) do |item|
        item.desc = "Update update info files"

        item.process do
          Package::PackageHandler.write_info_files(model[:location], force: model[:force])
        end

        item.exception(Package::InvalidScenario) do |e|
          cmd.abort(e)
        end
      end
    end

    PionePackage.define_subcommand("update", PionePackageUpdate)
  end
end
