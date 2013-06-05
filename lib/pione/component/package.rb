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
        return :directory if @location.directory?
        if File.extname(@location.basename) == ".pione"
          return :pione_document_file
        end
        raise ArgumentError.new(@location)
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
          scenarios: find_scenarios,
          documents: find_documents(info["PackageName"])
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
      def find_scenarios
        if (@location + "scenario" + "scenario.yml").exist?
          [PackageScenarioReader.read(@location + "scenario")]
        else
          if (@location + "scenario").exist? and (@location + "scenario").directory?
            (@location + "scenario").entries.map do |scenario|
              PackageScenarioReader.read(scenario)
            end.compact
          else
            []
          end
        end
      end

      # Find documents from the packcage location.
      #
      # @return [Array<Document>]
      #   documents
      def find_documents(package_name)
        @location.entries.select do |entry|
          entry.file? and entry.path.extname == ".pione"
        end.map {|entry| Document.load(entry, package_name) }
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
      attr_reader :info

      forward_as_key :@info, "ScenarioName", :name

      # @param location [BasicLocation]
      #   scenario location
      # @param info [Hash]
      #   scenario information table
      def initialize(location, info)
        @location = location
        @info = info
      end

      # Return the input location. If the scenario doesn't have input location,
      # return nil.
      #
      # @return [BasicLocation]
      #   the input location
      def input
        input_location = @location + "input"
        input_location if input_location.exist?
      end

      # Return the output location.
      #
      # @return [BasicLocation]
      #   the output location
      def output
        @location + "output"
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
      def self.read(location)
        new(location).read
      end

      # @param location [Location]
      #   the scenario location
      def initialize(location)
        @location = location
      end

      # Read scenario files.
      #
      # @return [PackageScenario]
      #   the scenario
      def read
        begin
          info = read_scenario_informations
          PackageScenario.new(@location, info)
        rescue
          nil
        end
      end

      private

      # Read scenario information table.
      #
      # @return [Hash]
      #   scenario information table
      def read_scenario_informations
        path = @location + "scenario.yml"
        if path.exist?
          YAML.load(path.read)
        else
          {"ScenarioName" => @location.basename}
        end
      end
    end
  end
end

