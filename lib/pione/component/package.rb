module Pione
  module Component
    # InvalidPackageError raises when the package is something bad.
    class InvalidPackageError < StandardError
      attr_reader :package

      def initialize(package, msg)
        @package = package
        @msg = msg
      end

      def message
        @msg
      end
    end

    # Package is a container of rules, scripts, scenarios, and etc.
    class Package < StructX
      member :info, default: {}
      member :bin
      member :scenarios, default: []
      member :documents, default: []

      forward_as_key Proc.new{info}, "PackageName", :name
      forward :@unified_document, :find, :find_rule
      forward! :@unified_document, :rules, :create_root_rule, :params

      def initialize(*args)
        super(*args)
        build_unified_document
        validate
      end

      # Return the package ID. Package ID is the hash ID of git repository or the version.
      def package_id
        info["HashID"] || info["Version"]
      end

      # Upload the package files to the location.
      #
      # @return [void]
      def upload(dest)
        if bin and bin.exist?
          # upload bin files
          bin.entries.each do |entry|
            entry.copy(dest + name + "bin" + entry.basename)
          end
        end
      end

      # Find scenario that have the name.
      #
      # @param name [String]
      #   scenario name
      # @return [PackageScenario]
      #   the scenario
      def find_scenario(name)
        if name == :anything
          scenarios.first
        else
          scenarios.find {|scenario| scenario.name == name}
        end
      end

      private

      # Build an unified document from all documents in the package.
      def build_unified_document
        rules = documents.map{|doc| doc.rules}.flatten
        params = documents.inject(Model::Parameters.empty) do |_params, document|
          _params.merge(document.params)
        end
        @unified_document = Component::Document.new(name, rules, params)
      end

      # Validate package consistency.
      def validate
        @unified_document.rules.map{|rule| rule.path}.sort.inject do |prev, elt|
          if prev == elt
            msg = "There are duplicated rules '%s' in the package '%s'"
            raise InvalidPackage.new(self, msg % [name, package])
          else
            elt
          end
        end
      end
    end

    # PackageReader is a reader for packages.
    class PackageReader
      class << self
        # Read a pacakge from the location.
        #
        # @param location [Location::BasicLocation]
        #   location of package
        # @return [Package]
        #   the package
        def read(location)
          new(location).read
        end
      end

      attr_reader :location
      attr_reader :type

      # @param location [Location]
      #   package location
      def initialize(location)
        @location = location
        @type = check_package_type
      end

      # Return the location of package information file.
      def info_location
        @location + "package.yml"
      end

      # Read the package.
      #
      # @return [Package]
      #   the package
      def read
        case @type
        when :directory
          return read_package_directory
        when :pione_document_file
          return read_pione_document_file
        end
      end

      private

      # Check package type.
      #
      # @return [Symbol]
      #   package type
      def check_package_type
        case File.extname(@location.basename)
        when ".ppg"
          return :archive
        when ".pione"
          return :pione_document_file
        else
          return :directory
        end
      end

      # Read package directory.
      #
      # @return [Package]
      #   the package
      def read_package_directory
        info = read_package_info
        Package.new(
          info: info,
          bin: @location + "bin",
          scenarios: find_scenarios(info["Scenarios"]),
          documents: find_documents(info["PackageName"], info["Documents"])
        )
      end

      # Read PIONE document.
      #
      # @return [Package]
      #   the package
      def read_pione_document_file
        document = Component::Document.load(@location, "Main")
        Package.new(info: {"PackageName" => "Main"}, documents: [document])
      end

      # Read the informations from the package location.
      #
      # @return [Hash]
      #   package information table
      def read_package_info
        YAML.load((@location + "package.yml").read)
      rescue Location::NotFound
        raise InvalidPackageError.new(self, "package.yml not found in %s" % @location.uri)
      end

      # Find scenarios from the package location.
      #
      # @return [Array<PackageScenario>]
      #   scenarios
      def find_scenarios(scenarios)
        return [] if scenarios.nil?
        scenarios.map do |path|
          if (@location + path + "scenario.yml").exist?
            PackageScenarioReader.read(@location, path)
          end
        end.compact
      end

      # Find documents from the packcage location.
      #
      # @return [Array<Document>]
      #   documents
      def find_documents(package_name, document_names)
        document_names.map do |name|
          Document.load(@location + name, package_name, name)
        end
      end
    end

    # RehearsalResult represents error result of rehearsal test.
    class RehearsalResult < StructX
      member :key
      member :name

      # Create an error message.
      def to_s
        case key
        when :different
          "%s is different from expected result." % name
        when :not_exist
          "%s doesn't exist." % name
        end
      end
    end

    # PackageScenario is a class for expected scenario of rule's behavior.
    class PackageScenario
      include SimpleIdentity

      attr_reader :location
      attr_reader :package_path
      attr_reader :info

      forward_as_key :@info, "ScenarioName", :name

      # @param location [BasicLocation]
      #   scenario location
      # @param info [Hash]
      #   scenario information table
      def initialize(location, package_path, info)
        @location = location
        @package_path = package_path
        @info = info
        @package_path = package_path
      end

      # Return the input location. If the scenario doesn't have input location,
      # return nil.
      #
      # @return [BasicLocation]
      #   the input location
      def input
        input_location = @location + @package_path + "input"
        input_location if input_location.exist?
      end

      # Return input file locations.
      #
      # @return [BasicLocation]
      #   input file locations
      def inputs
        if info.has_key?("Inputs")
          info["Inputs"].map {|name| @location + @package_path + "input" + name}
        else
          []
        end
      end

      # Return the output location.
      #
      # @return [BasicLocation]
      #   the output location
      def output
        @location + @package_path + "output"
      end

      # Return output file locations.
      #
      # @return [BasicLocation]
      #   output file locations
      def outputs
        if info.has_key?("Outputs")
          info["Outputs"].map {|name| @location + @package_path + "output" + name}
        else
          []
        end
      end

      # Validate reheasal results.
      def validate(result_location)
        return [] unless output.exist?

        errors = []
        output.entries.each do |entry|
          name = entry.basename
          result = result_location + name
          if result.exist?
            if entry.read != result.read
              errors << RehearsalResult.new(:different, name)
            end
          else
            errors << RehearsalResult.new(:not_exist, name)
          end
        end
        return errors
      end
    end

    # PackageScenarioReader is a reader for loading scenarios.
    class PackageScenarioReader
      # Read scenario from the location.
      def self.read(location, package_path)
        new(location, package_path).read
      end

      attr_reader :location
      attr_reader :package_path

      # @param location [Location]
      #   the scenario location
      def initialize(location, package_path)
        @location = location
        @package_path = package_path
      end

      # Return the location of scenario information file.
      def info_location
        @location + @package_path + "scenario.yml"
      end

      # Read scenario files.
      #
      # @return [PackageScenario]
      #   the scenario
      def read
        begin
          info = read_scenario_informations
          PackageScenario.new(@location, @package_path, info)
        rescue
          nil
        end
      end

      private

      # Read scenario informations.
      #
      # @return [Hash]
      #   scenario information table
      def read_scenario_informations
        path = info_location
        if path.exist?
          YAML.load(path.read)
        else
          {"ScenarioName" => (@location + @package_path).basename}
        end
      end
    end

    # PackageArchiver makes PPG file as PIONE archive.
    class PackageArchiver
      attr_reader :location

      forward :@package, :name, :package_name
      forward :@package, :package_id

      # @param location [BasicLoaction]
      #   package location
      def initialize(location)
        @location = location
        @reader = PackageReader.new(location)
        @package = @reader.read
      end

      # Create a package archive file.
      #
      # @param output_location [BasicLocation]
      #   location of the archive file
      def archive(output_location)
        path = Temppath.create
        Zip::Archive.open(path.to_s, Zip::CREATE) do |ar|
          archive_package_info(ar)
          archive_documents(ar)
          archive_scenarios(ar)
        end
        Location[path].copy(output_location)
      end

      private

      def archive_package_info(ar)
        ar.add_buffer("package.yml", @reader.info_location.to_s)
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

