module Pione
  module Package
    # PackageArchiver makes PPG file as PIONE archive.
    class PackageArchiver
      attr_reader :location

      def initialize(location)
        unless location.scheme == "local"
          raise Location::NotLocal.new(location)
        end
        @location = location
        @package_info = PackageInfo.read((location + "pione-package.json").read)
      end

      # Create a package archive file.
      #
      # @param output_directory_location [DataLocation]
      #   the location of output directory
      # @param show_directory [Boolean]
      #   flag for appending digest to filename
      def archive(output_directory_location, show_digest)
        path = Temppath.create
        info = PackageInfo.read((@location + "pione-package.json").read)

        # archive
        Zip::Archive.open(path.to_s, Zip::CREATE) do |ar|
          archive_package_info(ar)
          archive_documents(ar, info)
          archive_scenarios(ar)
          archive_bins(ar, info)
        end

        # make output location
        digest = show_digest ? Util::PackageDigest.generate(Location[path]) : nil
        output_location = output_directory_location + filename(digest)

        # copy the archive file to output location
        Location[path].copy(output_location)

        return output_location
      end

      private

      # Return PPG filename.
      def filename(digest)
        PackageFilename.new(
          package_name: @package_info.name,
          editor: @package_info.editor,
          tag: @package_info.tag,
          digest: digest
        ).to_s
      end

      # Archive package info file.
      def archive_package_info(ar)
        ar.add_buffer("pione-package.json", (@location + "pione-package.json").read)
      end

      # Archive documents based on package info file.
      def archive_documents(ar, info)
        info.documents.each do |document|
          ar.add_buffer(document, (@location + document).read)
        end
      end

      # Archive scenarios. This method adds scenario directory, scenario info
      # file, inputs, and outputs to the archive based on scenario info file.
      def archive_scenarios(ar)
        @package_info.scenarios.each do |scenario|
          info = ScenarioInfo.read((@location + scenario + "pione-scenario.json").read)
          ar.add_dir(scenario)
          archive_scenario_document(ar, scenario)
          archive_scenario_info(ar, scenario)
          archive_scenario_inputs(ar, scenario, info)
          archive_scenario_outputs(ar, scenario, info)
        end
      end

      # Archive scenario document file.
      def archive_scenario_document(ar, scenario)
        document_location = @location + scenario + "Scenario.pione"
        ar.add_buffer(File.join(scenario, "Scenario.pione"), document_location.read)
      end

      # Archive scenario info file.
      def archive_scenario_info(ar, scenario)
        info_location = @location + scenario + "pione-scenario.json"
        ar.add_buffer(File.join(scenario, "pione-scenario.json"), info_location.read)
      end

      # Archive input data of the scenario.
      def archive_scenario_inputs(ar, scenario, info)
        if not(info.inputs.empty?)
          ar.add_dir(File.join(scenario, "input"))
          info.inputs.each do |input|
            input_location = @location + scenario + input
            ar.add_buffer(File.join(scenario, input), input_location.read)
          end
        end
      end

      # Archive output data of the scenario.
      def archive_scenario_outputs(ar, scenario, info)
        if not(info.outputs.empty?)
          ar.add_dir(File.join(scenario, "output"))
          info.outputs.each do |output|
            output_location = @location + scenario + output
            ar.add_buffer(File.join(scenario, output), output_location.read)
          end
        end
      end

      def archive_bins(ar, info)
        info.bins.each do |bin|
          ar.add_buffer(bin, (@location + bin).read)
        end
      end
    end
  end
end
