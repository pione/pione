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

        # make digest
        digest = Util::PackageDigest.generate(@location)

        # archive
        Zip::File.open(path.to_s, Zip::File::CREATE) do |zip|
          archive_package_info(zip)
          archive_documents(zip, info)
          archive_scenarios(zip)
          archive_bins(zip, info)
          archive_files(zip, info)
          archive_digest(zip, digest)
        end

        # make output location
        output_location = output_directory_location + filename(show_digest ? digest : nil)

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
      def archive_package_info(zip)
        add_file_with_time(zip, "pione-package.json", @location + "pione-package.json")
      end

      # Archive documents based on package info file.
      def archive_documents(zip, info)
        info.documents.each do |document|
          add_file_with_time(zip, document, @location + document)
        end
      end

      # Archive scenarios. This method adds scenario directory, scenario info
      # file, inputs, and outputs to the archive based on scenario info file.
      def archive_scenarios(zip)
        @package_info.scenarios.each do |scenario|
          info = ScenarioInfo.read((@location + scenario + "pione-scenario.json").read)

          # make the scenario directory
          mkdir_with_time(zip, scenario, (@location + scenario).mtime)

          # archive scenario contents
          archive_scenario_document(zip, scenario)
          archive_scenario_info(zip, scenario)
          archive_scenario_inputs(zip, scenario, info)
          archive_scenario_outputs(zip, scenario, info)
        end
      end

      # Archive scenario document file.
      def archive_scenario_document(zip, scenario)
        document_location = @location + scenario + "Scenario.pione"
        add_file_with_time(zip, File.join(scenario, "Scenario.pione"), document_location)
      end

      # Archive scenario info file.
      def archive_scenario_info(zip, scenario)
        info_location = @location + scenario + "pione-scenario.json"
        add_file_with_time(zip, File.join(scenario, "pione-scenario.json"), info_location)
      end

      # Archive input data of the scenario.
      def archive_scenario_inputs(zip, scenario, info)
        if not(info.inputs.empty?)
          # make scenario input directory
          mkdir_with_time(zip, File.join(scenario, "input"), (@location + scenario + "input").mtime)

          # archive input data
          info.inputs.each do |input|
            input_location = @location + scenario + input
            add_file_with_time(zip, File.join(scenario, input), input_location)
          end
        end
      end

      # Archive output data of the scenario.
      def archive_scenario_outputs(zip, scenario, info)
        if not(info.outputs.empty?)
          # make scenario output directory
          mkdir_with_time(zip, File.join(scenario, "output"), (@location + scenario + "output").mtime)

          info.outputs.each do |output|
            output_location = @location + scenario + output
            add_file_with_time(zip, File.join(scenario, output), output_location)
          end
        end
      end

      def archive_bins(zip, info)
        info.bins.each do |bin|
          add_file_with_time(zip, bin, @location + bin)
        end
      end

      def archive_files(zip, info)
        info.files.each do |file|
          add_file_with_time(zip, file, @location + file)
        end
      end

      def archive_digest(zip, digest)
        digest_location = Location[Temppath.create]
        digest_location.write(digest)
        add_file_with_time(zip, ".digest", digest_location)
      end

      def mkdir_with_time(zip, path, time)
        zip.mkdir(path)
        entry = zip.get_entry(path)
        entry.time = Zip::DOSTime.at(time)
        entry.extra.delete("UniversalTime")
      end

      def add_file_with_time(zip, path, orig_location)
        entry = zip.add(path, orig_location.path.to_s)
        entry.time = Zip::DOSTime.at(orig_location.mtime)
        entry.extra.delete("UniversalTime")
      end
    end
  end
end
