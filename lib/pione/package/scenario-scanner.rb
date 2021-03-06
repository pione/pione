module Pione
  module Package
    # ScenarioScanner scans scenario location.
    class ScenarioScanner
      class << self
        def scenario?(location)
          not(/^\./.match(location.basename)) and (location + "Scenario.pione").exist?
        end

        def scan(location)
          new(location).scan
        end
      end

      # Create a scanner with the location. The location should be local scheme.
      def initialize(location)
        unless location.local?
          raise Location::NotLocal.new(location)
        end
        @location = location
      end

      # Scan the scenario directory and return scenario informations. If the
      # location is not scenario directory, return false.
      def scan
        unless self.class.scenario?(@location)
          return false
        else
          name, param_set = scan_annotations
          inputs = scan_data_dir("input")
          outputs = scan_data_dir("output")
          ScenarioInfo.new(name: name, textual_param_sets: param_set, inputs: inputs, outputs: outputs)
        end
      end

      # Scan annotations from scenario file and return scenario name and
      # parameter set.
      def scan_annotations
        location = @location + "Scenario.pione"

        # setup fake language environment
        env = Lang::Environment.new.setup_new_package("ScenarioScanner")

        # parse the scenario document
        Document.load(env, location, nil, nil, nil, @location + "Scenario.pione")

        # get name and parameter set from fake package's annotations
        annotations = env.package_get(Lang::PackageExpr.new(package_id: env.current_package_id)).annotations
        name = find_name(annotations)
        param_set = find_param_set(annotations)

        return name, param_set
      rescue Parslet::ParseFailed => e
        raise InvalidScenario.new(location, "Parser failed: " + e.message)
      end

      # Scan data files.
      def scan_data_dir(name)
        if (@location + name).exist?
          (@location + name).file_entries.each_with_object([]) do |entry, target|
            unless /^\./.match(entry.basename)
              target << File.join(name, entry.basename)
            end
          end
        else
          return []
        end
      end

      # Find "ScenarioName" annotaion.
      def find_name(annotations)
        location = @location + "Scenario.pione"
        names = annotations.select {|annotation| annotation.annotation_type == "ScenarioName"}
        case names.size
        when 0
          raise InvalidScenario.new(location, "No scenario name exists.")
        when 1
          names.first.value
        else
          name_list = names.map {|name| name.value}.join(", ")
          raise InvalidScenario.new(location, "Duplicated scenario name found." % name_list)
        end
      end

      # Find "ParamSet" annotaion.
      def find_param_set(annotations)
        param_sets = annotations.select {|annotation| annotation.annotation_type == "ParamSet"}
        case param_sets.size
        when 0
          return nil
        when 1
          param_sets.first.value
        else
          location = @location + "Scenario.pione"
          raise InvalidScenario.new(location, "Duplicated parameter set found.")
        end
      end
    end
  end
end
