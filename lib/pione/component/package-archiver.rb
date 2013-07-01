module Pione
  module Component
    # PackageArchiver makes PPG file as PIONE archive.
    class PackageArchiver
      attr_reader :location

      # @param location [BasicLoaction]
      #   the location of package
      def initialize(location, option={})
        if location.location_type == :git_repository
          location = location + option
        end
        @package = PackageReader.read(location)
        @location = @package.location
        @tag = option[:tag]
        @branch = option[:branch]
      end

      # Create a package archive file.
      #
      # @param output_location [BasicLocation]
      #   the location of output directory
      def archive(output_location)
        output = output_location + filename
        path = Temppath.create
        Zip::Archive.open(path.to_s, Zip::CREATE) do |ar|
          archive_package_info(ar)
          archive_documents(ar)
          archive_scenarios(ar)
        end
        Location[path].copy(output)
        return output
      end

      private

      def filename
        PackageFilename.new(
          package_name: @package.name,
          edition: @package.edition,
          tag: @tag || @branch || @package.tag,
          hash_id: @package.hash_id
        ).to_s
      end

      def archive_package_info(ar)
        ar.add_buffer("package.yml", (@location + "package.yml").read)
      end

      def archive_documents(ar)
        @package.documents.each do |doc|
          ar.add_buffer(doc.package_path, (@location + doc.package_path).read)
        end
      end

      def archive_scenarios(ar)
        @package.scenarios.each do |scenario|
          ar.add_dir(scenario.package_path)
          archive_scenario_info(ar, scenario)
          archive_scenario_inputs(ar, scenario)
          archive_scenario_outputs(ar, scenario)
        end
      end

      def archive_scenario_info(ar, scenario)
        package_path = File.join(scenario.package_path, "scenario.yml")
        location = @location + scenario.package_path + "scenario.yml"
        ar.add_buffer(package_path, location.read)
      end

      def archive_scenario_inputs(ar, scenario)
        if not(scenario.inputs.empty?)
          ar.add_dir(File.join(scenario.package_path, "input"))
          scenario.inputs.each do |input|
            package_path = File.join(scenario.package_path, "input", input.basename)
            ar.add_buffer(package_path, input.read)
          end
        end
      end

      def archive_scenario_outputs(ar, scenario)
        if not(scenario.outputs.empty?)
          ar.add_dir(File.join(scenario.package_path, "output"))
         scenario.outputs.each do |output|
            package_path = File.join(scenario.package_path, "output", output.basename)
            ar.add_buffer(package_path, output.read)
          end
        end
      end
    end
  end
end
