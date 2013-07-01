module Pione
  module Command
    class PionePackage < BasicCommand
      define_info do
        set_name "pione-package"
        set_banner "PIONE package utility."
      end

      define_option do
        use :color
        use :debug

        default :output, Location["./"]

        define(:build) do |item|
          item.long = '--build'
          item.desc = 'build PIONE archive file(*.ppg)'
          item.action = lambda do |option, location|
            option[:action] = :build
          end
        end

        define(:output) do |item|
          item.short = "-o"
          item.long = "--output=LOCATION"
          item.desc = "output file or directory location"
          item.value = lambda {|val| Location[val]}
        end

        define(:tag) do |item|
          item.long = "--tag=NAME"
          item.desc = "specify tag name"
          item.value = :as_is
        end

        define(:tag) do |item|
          item.long = "--branch=NAME"
          item.desc = "specify branch name"
          item.value = :as_is
        end

        define(:hash_id) do |item|
          item.long = "--hash-id=HASH"
          item.desc = "specify git hash id"
          item.value = :as_is
        end

        validate do |option|
          unless option[:output].directory?
            abort("output location should be a directory: %s" % option[:output])
          end
        end
      end

      start do
        if option[:action] == :build
          # package is not found
          if @argv.first.nil?
            abort("There are no PIONE documents or packages.")
          end

          # archive
          if ppg = try_to_archive(Location[git: @argv.first], Location[data: @argv.first])
            puts "suceeded: %s" % ppg.address
          else
            abort("Faild to archive.")
          end
        end
      end

      private

      def archive_from_directory_package
        archiver = Component::PackageArchiver.new(Location[@argv.first])
      end

      def try_to_archive(*locations)
        locations.each do |location|
          begin
            # make archiver
            archiver_option = {tag: option[:tag], branch: option[:branch], hash_id: option[:hash_id]}
            if location.location_type == :data
              archiver_option[:tag] = Time.now.strftime("%Y%m%d%H%M")
            end
            archiver = Component::PackageArchiver.new(location, archiver_option)

            # archive
            return archiver.archive(option[:output])
          rescue => e
            Util::ErrorReport.warn("archiver faild: %s" % location, self, e, __FILE__, __LINE__)
          end
        end
        return false
      end
    end
  end
end
