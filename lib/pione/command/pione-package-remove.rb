module Pione
  module Command
    # `PionePackageRemove` is a subcommand that removes PIONE package from package
    # database in your system.
    class PionePackageRemove < BasicCommand
      #
      # informations
      #

      define(:name, "remove")
      define(:desc, "Remove the package from package database")

      #
      # arguments
      #

      argument(:target) do |item|
        item.type = :string
        item.desc = "package name that is removed from package database"
        item.missing = "There are no package name."
      end

      #
      # options
      #

      option(:editor) do |item|
        item.type = :string
        item.long = "--editor"
        item.arg  = "NAME"
        item.desc = "Specify editor name"
      end

      option(:tag) do |item|
        item.type = :string
        item.long = "--tag"
        item.arg  = "NAME"
        item.desc = "Specify tag name"
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << :db
      end

      setup(:db) do |item|
        item.desc = "Setup package database"

        item.assign(:db) do
          Package::Database.load
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :remove_package
        seq << :show
      end

      execution(:remove_package) do |item|
        item.desc = "Remove the package from package database"

        item.process do
          if model[:db].exist?(model[:target], model[:editor], model[:tag])
            model[:db].delete(model[:target], model[:editor], model[:tag])
            model[:db].save
            model[:removed] = true
          end
        end
      end

      execution(:show) do |item|
        item.desc = "Show the result"

        item.assign(:additions) do
          Array.new
        end

        item.process do
          test(model[:editor])
          model[:additions] << "editor: %s" % model[:editor]
        end

        item.process do
          test(model[:tag])
          model[:additions] << "tag: %s" % model[:tag]
        end

        item.assign(:info) do
          model[:additions].size > 0 ? "(" + model[:additions].join(", ") + ")" : ""
        end

        # show log
        item.process do
          arg = {name: model[:target], info: model[:info]}
          if model[:removed]
            Log::SystemLog.info(
              'Package "%{name}"%{info} has been removed from package database.' % arg
            )
          else
            Log::SystemLog.info(
              'Package "%{name}"%{info} not found in package database.' % arg
            )
          end
        end
      end
    end

    PionePackage.define_subcommand("remove", PionePackageRemove)
  end
end
