module Pione
  module Package
    class ScenarioInfo < StructX
      member :name
      member :textual_param_sets
      member :inputs, default: lambda {Array.new}
      member :outputs, default: lambda {Array.new}

      # Read the scenario information JSON source. The source is a string or
      # location of the file.
      def self.read(src)
        data = JSON.load(src.is_a?(Location::DataLocation) ? src.read : src)
        new(name: data["ScenarioName"], textual_param_sets: data["ParamSet"], inputs: data["Inputs"], outputs: data["Outputs"])
      end

      # Return file paths of the scenario.
      def filepaths
        list = []
        list << "Scenario.pione"
        list += inputs
        list += outputs
        return list
      end

      def to_json(*args)
        data = Hash.new
        data["ScenarioName"] = name
        data["ParamSet"] = textual_param_sets
        data["Inputs"] = inputs
        data["Outputs"] = outputs
        data.to_json(*args)
      end
    end
  end
end
