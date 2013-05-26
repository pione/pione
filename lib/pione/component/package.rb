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

    # Package is a container of rules, script, scenario, and etc.
    class Package
      include SimpleIdentity

      attr_reader :info
      attr_reader :bin
      attr_reader :scenarios
      attr_reader :documents
      attr_reader :rules
      attr_reader :params

      forward_as_key :@info, "PackageName", :name

      # @param info [Hash]
      #   package information table
      # @param bin [Location]
      #   package bin directory
      # @param scenarios [Array<PackageScenario>]
      #   scenarios
      # @param documents [Array<Document>]
      #   PIONE documents
      def initialize(info, bin, scenarios, documents)
        @info = info
        @bin = bin
        @scenarios = scenarios
        @documents = documents
        build_rules
        build_params
      end

      # Return the package entry rule.
      #
      # @return [Rule]
      #   entry rule
      def main
        @rules["&%s:Main" % name].tap{|x| x.condition.params.merge!(@params)}
      end

      # Return the named rule.
      #
      # @param [String] name
      #   rule path
      # @return [Rule]
      #   the rule
      def [](name)
        @rules[name].params.merge!(@params)
        @rules[name]
      end

      # Return root rule.
      #
      # @param prams [Parameters]
      #   root parameters
      # @return [RootRule]
      #   root rule
      def root_rule(params)
        Component::RootRule.new(main, @params.merge(params))
      end

      # Upload the package files to the location.
      #
      # @return [void]
      def upload(dest)
        if @bin.exist?
          # upload bin files
          @bin.entries.each do |entry|
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
          @scenarios.first
        else
          @scenarios.find {|scenario| scenario.name == name}
        end
      end

      private

      # Build rules from all documents in the package.
      def build_rules
        @rules = {}
        @documents.each do |doc|
          doc.rules.each do |name, rule|
            unless @rules[name]
              @rules[name] = rule
            else
              raise InvalidPackage.new(self, "duplicated rules: %s" % name)
            end
          end
        end
      end

      # Build parameters from all documents in the package.
      def build_params
        @params = Model::Parameters.empty
        @documents.each do |doc|
          doc.params.each do |param|
            @params.merge!(param)
          end
        end
      end
    end

    # PackageReader is a reader for packages.
    class PackageReader
      # @param location [Location]
      #   package location
      def initialize(location)
        @location = location
      end

      # Read the package.
      #
      # @return [Package]
      #   the package
      def read
        infos = read_package_info
        bin = @location + "bin"
        scenarios = find_scenarios
        documents = find_documents(infos["PackageName"])
        Package.new(infos, bin, scenarios, documents)
      end

      private

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
          (@location + "scenario").entries.map do |scenario|
            PackageScenarioReader.read(scenario)
          end.compact
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

