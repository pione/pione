module Pione
  module Command
    # `PionePackageBuild` is a subcommand that builds PIONE archive package.
    class PionePackageBuild < BasicCommand
      #
      # basic informations
      #

      command_name "pione package build"
      command_banner "build PIONE archive package"

      #
      # options
      #

      use_option :color
      use_option :debug

      option_default :output, Location["./"]

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

      define_option(:hash_id) do |item|
        item.long = "--hash-id=HASH"
        item.desc = "specify git hash id"
        item.value = :as_is
      end

      validate_option do |option|
        unless option[:output].directory?
          abort("Output location should be a directory: %s" % option[:output])
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

      execute :build_package

      # Build a PPG package.
      def execute_build_package
        if ppg = try_to_archive(Location[git: @target], Location[data: @target])
          Log::SystemLog.info("Package build suceeded: %s" % ppg.address)
        else
          abort("Package build faild to archive.")
        end
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
            Log::Debug.system("PIONE failed to archive %s: %s" % [location, e.message])
          end
        end
        return false
      end
    end
  end
end
