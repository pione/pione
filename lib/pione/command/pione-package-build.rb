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
      def build_package(location)
        local_location = location.local

        # action documents
        actions = read_action_documents(local_location)

        # compile
        local_location.each_entry do |entry|
          if (entry.extname == ".pnml")
            flow_name = entry.basename(".pnml")
            net = PNML::Reader.read(entry)
            option = {
              :flow_name => flow_name,
              :literate_actions => actions,
            }
            content = PNML::Compiler.new(net, option).compile
            file = entry.dirname + (flow_name + ".pione")
            file.write(content)
          end
        end

        # update
        Package::PackageHandler.write_info_files(local_location, force: true)

        handler = Package::PackageReader.read(local_location)
        cache_location = Package::PackageCache.directory_cache(handler.digest)

        # make archiver
        archiver = Package::PackageArchiver.new(cache_location)

        # archive
        return archiver.archive(model[:output], false)
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
            actions.merge!(LiterateAction::MarkdownParser.parse(entry.read))
          end
        end
      end
    end

    PionePackageBuild.define(:process_context_class, PionePackageBuildContext)

    PionePackage.define_subcommand("build", PionePackageBuild)
  end
end
