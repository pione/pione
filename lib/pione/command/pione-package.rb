module Pione
  module Command
    # PionePackage is a command body of "pione-package".
    class PionePackage < BasicCommand
      #
      # basic informations
      #

      command_name "pione-package"
      command_banner "PIONE package utility."

      #
      # options
      #

      use_option :color
      use_option :debug

      option_default :output, Location["./"]

      define_option(:add) do |item|
        item.long = '--add'
        item.desc = 'add the package to package database'
        item.action = lambda do |_, option, location|
          option[:action_mode] = :add
        end
      end

      define_option(:build) do |item|
        item.long = '--build'
        item.desc = 'build PIONE archive file(*.ppg)'
        item.action = lambda do |_, option, location|
          option[:action_mode] = :build
        end
      end

      define_option(:write_info) do |item|
        item.long = '--write-info'
        item.desc = 'write package and scenario info files'
        item.action = lambda do |_, option, location|
          option[:action_mode] = :write_info
        end
      end

      define_option(:output) do |item|
        item.short = "-o"
        item.long = "--output=LOCATION"
        item.desc = "output file or directory location"
        item.value = lambda {|val| Location[val]}
      end

      define_option(:tag) do |item|
        item.long = "--tag=NAME"
        item.desc = "specify tag name"
        item.value = :as_is
      end

      define_option(:tag) do |item|
        item.long = "--branch=NAME"
        item.desc = "specify branch name"
        item.value = :as_is
      end

      define_option(:hash_id) do |item|
        item.long = "--hash-id=HASH"
        item.desc = "specify git hash id"
        item.value = :as_is
      end

      validate_option do |option|
        unless option[:output].directory?
          abort("output location should be a directory: %s" % option[:output])
        end
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

      execute :add => :add_package

      # Add the package to package database.
      def execute_add_package
        handler = Package::PackageReader.read(Location[@target])
        db = Package::Database.load
        db.add(name: handler.info.name, edition: handler.info.edition, tag: handler.info.tag, digest: handler.digest)
        db.save
        Log::SystemLog.info("added %s" % handler.info.name)
      end

      execute :build => :build_package

      # Build a PPG package.
      def execute_build_package
        if ppg = try_to_archive(Location[git: @target], Location[data: @target])
          Log::SystemLog.info("pione-package suceeded to build %s" % ppg.address)
        else
          abort("pione-package faild to archive.")
        end
      end

      execute :write_info => :write_info

      # Update update info files.
      def execute_write_info
        Package::PackageHandler.write_info_files(Location[@target])
      end

      #
      # helper methods
      #

      private

      def try_to_archive(*locations)
        locations.each do |location|
          begin
            handler = Package::PackageReader.read(location)
            cache_location = Package::PackageCache.directory_cache(handler.digest)

            # make archiver
            archiver = Package::PackageArchiver.new(cache_location)

            # archive
            return archiver.archive(option[:output], false)
          rescue => e
            p e
            Log::Debug.system("pione-package failed to archive %s: %s" % [location, e.message])
          end
        end
        return false
      end
    end
  end
end
