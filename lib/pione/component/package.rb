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
      member :location
      member :info, default: {}
      member :bin
      member :scenario_paths, default: []
      member :documents, default: []

      forward_as_key Proc.new{info}, "PackageName", :name
      forward_as_key Proc.new{info}, "Edition", :edition
      forward_as_key Proc.new{info}, "Tag", :tag
      forward_as_key Proc.new{info}, "HashID", :hash_id
      forward :@unified_document, :find, :find_rule
      forward! :@unified_document, :rules, :create_root_rule, :params

      def initialize(*args)
        super(*args)
        info["Edition"] = "origin" unless info["Edition"]
        build_unified_document
        validate
      end

      def scenarios
        scenario_paths.map {|path| PackageScenarioReader.read(location, path)}
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
        scenario_paths.each do |path|
          if name == :anything
            return PackageScenarioReader.read(location, path)
          else
            scenario = PackageScenarioReader.read(location, path)
            return scenario if scenario.name == name
          end
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
      forward_as_key :@info, "Edition", :edition
      forward_as_key :@info, "Version", :version
      forward_as_key :@info, "Date", :date

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
  end
end

