module Pione
  module Package
    class ScenarioInfo < StructX
      member :name
      member :param_set
      member :inputs, default: lambda {Array.new}
      member :outputs, default: lambda {Array.new}

      # Read the scenario information JSON source. The source is a string or
      # location of the file.
      def self.read(src)
        data = JSON.load(src.is_a?(Location::DataLocation) ? src.read : src)
        new(name: data["ScenarioName"], param_set: data["ParamSet"], inputs: data["Inputs"], outputs: data["Outputs"])
      end

      # Return file paths of the scenario.
      def filepaths
        list = []
        list += inputs
        list += outputs
        return list
      end

      def to_json(*args)
        data = Hash.new
        data["ScenarioName"] = name
        data["ParamSet"] = param_set
        data["Inputs"] = inputs
        data["Outputs"] = outputs
        data.to_json(*args)
      end
    end
  end
end
