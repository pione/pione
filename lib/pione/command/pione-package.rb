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
            option[:package_location] = Location[location]
          end
        end

        define(:output) do |item|
          item.short = "-o"
          item.long = "--output=LOCATION"
          item.desc = "output file or directory location"
          item.value = lambda {|val| Location[val]}
        end
      end

      start do
        if option[:action] == :build
          # package is not found
          if @argv.first.nil?
            abort("There are no PIONE documents or packages.")
          end

          # archiver
          archiver = Component::PackageArchiver.new(Location[@argv.first])

          # output
          output = option[:output]
          if output.directory?
            output = output + package_filename(archiver)
          end

          # archive
          archiver.archive(output)
        end
      end

      private

      def package_filename(archiver)
        name = archiver.package_name
        package_id = archiver.package_id
        "%s-%s.ppg" % [name, package_id]
      end
    end
  end
end
