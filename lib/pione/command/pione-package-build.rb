module Pione
  module Command
    # `PionePackageBuild` is a subcommand that builds PIONE archive package.
    class PionePackageBuild < BasicCommand
      #
      # informations
      #

      define(:name, "build")
      define(:desc, "Build PIONE archive package")

      #
      # arguments
      #

      argument(:source) do |item|
        item.type = :location
        item.desc = "the source package location"
        item.missing = "There are no PIONE documents or packages."
      end

      #
      # options
      #

      option CommonOption.color
      option CommonOption.debug

      option(:output) do |item|
        item.type  = :location
        item.short = "-o"
        item.long  = "--output"
        item.arg   = "LOCATION"
        item.desc  = "Output file or directory location"
        item.init  = "./"
      end

      option(:tag) do |item|
        item.type = :string
        item.long = "--tag"
        item.arg  = "NAME"
        item.desc = "Specify tag name"
      end

      option(:hash_id) do |item|
        item.type = :string
        item.long = "--hash-id"
        item.arg  = "HASH"
        item.desc = "Specify git hash ID"
      end

      option_post(:check_output_directory) do |item|
        item.desc = "Check output location is directory"

        item.process do
          test(not(model[:output].directory?))
          cmd.abort("Output location should be a directory: %s" % model[:output])
        end
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << :source_location
      end

      setup(:source_location) do |item|
        item.desc = "Setup source locations"

        item.assign(:source_location) do
          Location[data: model[:source].address]
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |seq|
        seq << :build_package
      end

      execution(:build_package) do |item|
        item.desc = "Build a PPG package"

        item.process do
          begin
            ppg = build_package(model[:source_location])
            Log::SystemLog.info('Package %s has been built successfully.' % ppg.address)
            cmd.terminate
          rescue => e
            cmd.abort("PIONE has failed to build a package of %s." % model[:source_location].address, exception: e)
          end
        end
      end
    end

    # `PionePackageBuildContext` is a context for `pione package build`.
    class PionePackageBuildContext < Rootage::CommandContext
      # Build a package of the location.
      #
      # @param location [Location]
      #   package directory location
      # @return [Location]
      #   location of the generated PPG file
      def build_package(location)
        local_location = location.local

        # action documents
        actions = read_action_documents(local_location)

        # compile
        compile_pnml(local_location, actions)

        # update
        update_package_info(local_location)

        # make archiver
        return archive_package(local_location, model[:output])
      end

      # Read actions from action documents(files that named "*.action.md").
      #
      # @param location [Location]
      #   package directory location
      # @return [Hash{String=>String}]
      #   relation table for rule name and the action content
      def read_action_documents(location)
        location.entries.each_with_object(Hash.new) do |entry, actions|
          if entry.basename.end_with?(".action.md")
            begin
              actions.merge!(LiterateAction::Parser.parse(entry.read))
            rescue
              Log::SystemLog.fatal("Error has occured when parsing the action document %s." % entry.address)
              raise
            end
          end
        end
      end

      # Compile all PNML files in the location.
      #
      # @param location [Location]
      #   package directory location
      # @param actions [Hash{String=>String}]
      #   relation table for rule name and the action content
      # @return [void]
      def compile_pnml(location, actions)
        location.each_entry do |entry|
          if (entry.extname == ".pnml")
            begin
              flow_name = entry.basename(".pnml")
              net = PNML::Reader.read(entry)
              option = {
                :flow_rule_name => flow_name,
                :literate_actions => actions,
              }
              content = PNML::Compiler.new(net, option).compile
              file = entry.dirname + (flow_name + ".pione")
              file.write(content)
            rescue
              Log::SystemLog.fatal("Error has occured when compiling the PNML file %s." % entry.address)
              raise
            end
          end
        end
      end

      # Update package information file.
      #
      # @param location [Location]
      #   package directory location
      # @return [void]
      def update_package_info(location)
        Package::PackageHandler.write_info_files(location, force: true)
      rescue
        Log::SystemLog.fatal("Error has occured when updating package information file.")
        raise
      end

      # Update package information file.
      #
      # @param location [Location]
      #   package directory location
      # @return [Location]
      #   location of the generated PPG file
      def archive_package(location, output)
        handler = Package::PackageReader.read(location)
        cache_location = Package::PackageCache.directory_cache(handler.digest)

        # make archiver
        archiver = Package::PackageArchiver.new(cache_location)

        # archive
        return archiver.archive(model[:output], false)
      end
    end

    PionePackageBuild.define(:process_context_class, PionePackageBuildContext)

    PionePackage.define_subcommand("build", PionePackageBuild)
  end
end
