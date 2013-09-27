module Pione
  module Command
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

      define_option(:build) do |item|
        item.long = '--build'
        item.desc = 'build PIONE archive file(*.ppg)'
        item.action = lambda do |_, option, location|
          option[:action_mode] = :build
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

      execute :build => :build_package

      # Build a PPG package.
      def execute_build_package
        if ppg = try_to_archive(Location[git: @target], Location[data: @target])
          puts "suceeded: %s" % ppg.address
        else
          abort("Faild to archive.")
        end
      end

      #
      # helper methods
      #

      private

      def try_to_archive(*locations)
        locations.each do |location|
          begin
            # make archiver
            archiver_option = {tag: option[:tag], branch: option[:branch], hash_id: option[:hash_id]}
            archiver = Package::PackageArchiver.new(location, archiver_option)

            # archive
            return archiver.archive(option[:output])
          rescue => e
            Log::Debug.system("pione-package failed to archive %s: %s" % [location, e.message])
          end
        end
        return false
      end
    end
  end
end
