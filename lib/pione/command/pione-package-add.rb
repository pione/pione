module Pione
  module Command
    # `PionePackageAdd` is a subcommand that adds PIONE package to package
    # database in your system.
    class PionePackageAdd < BasicCommand
      #
      # informations
      #

      define(:name, "add")
      define(:desc, "Add the package to package database")

      #
      # arguments
      #

      argument(:target) do |item|
        item.type = :location
        item.desc = "the package to add in package database"
        item.missing = "There are no PIONE documents or packages."
      end

      #
      # options
      #

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
        seq << :handler
        seq << :db
      end

      setup(:handler) do |item|
        item.desc = "Create a package handler and get informations"

        # create a package handler
        item.assign(:handler) do
          Package::PackageReader.read(model[:target])
        end

        # get package name
        item.assign(:name) do
          model[:handler].info.name
        end

        # get package editor
        item.assign(:editor) do
          model[:handler].info.editor
        end

        # get package tag
        item.assign(:tag) do
          test(not(model[:tag]))
          model[:handler].info.tag
        end

        # get package digest
        item.assign(:digest) do
          model[:handler].digest
        end
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
        seq << :add_package
        seq << :show
      end

      execution(:add_package) do |item|
        item.desc = "Add the package to package database"

        item.process do
          model[:db].add(
            name:   model[:name],
            editor: model[:editor],
            tag:    model[:tag],
            digest: model[:digest]
          )
          model[:db].save
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
          arg = {name: model[:name], info: model[:info]}
          Log::SystemLog.info(
            'Package "%{name}"%{info} was added to package database' % arg
          )
        end
      end
    end

    PionePackage.define_subcommand("add", PionePackageAdd)
  end
end
