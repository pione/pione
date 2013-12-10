module Pione
  module Command
    # `PionePackageAdd` is a subcommand that adds PIONE package to package
    # database in your system.
    class PionePackageAdd < BasicCommand
      #
      # basic informations
      #

      command_name "pione package add"
      command_banner "add the package to package database"

      #
      # options
      #

      define_option(:tag) do |item|
        item.long = "--tag=NAME"
        item.desc = "specify tag name"
        item.value = :as_is
      end

      #
      # command lifecycle: setup phase
      #

      setup :target

      # Check archiver target location.
      def setup_target
        abort("There are no PIONE documents or packages.")  if @argv.first.nil?
        @target = @argv.first
      end

      #
      # command lifecycle: execution phase
      #

      execute :add_package

      # Add the package to package database.
      def execute_add_package
        handler = Package::PackageReader.read(Location[@target])
        tag = option[:tag] || handler.info.tag
        db = Package::Database.load
        db.add(name: handler.info.name, editor: handler.info.editor, tag: tag, digest: handler.digest)
        db.save

        # show log
        args = []
        args << "editor: " + handler.info.editor if handler.info.editor
        args << "tag: " + handler.info.tag if handler.info.tag
        _args = args.size > 0 ? "(" + args.join(", ") + ")" : ""
        Log::SystemLog.info(
          "package \"%s\"%s was added to package database" % [handler.info.name, _args]
        )
      end
    end
  end
end
