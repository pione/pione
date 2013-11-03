module Pione
  module Package
    # ScenarioHandler handles scenario related operations.
    class ScenarioHandler
      include SimpleIdentity

      attr_reader :location
      attr_reader :info

      # @param location [BasicLocation]
      #   scenario location
      # @param info [Hash]
      #   scenario information table
      def initialize(location, info)
        @location = location
        @info = info
      end

      # Write an information file for the scenario.
      def write_info_file(option={})
        last_time = Util::LastTime.get(@info.filepaths.map{|path| @location + path})

        # update the scenario info file
        location = @location + "pione-scenario.json"
        if option[:force] or not(location.exist?) or last_time > location.mtime
          location.write(JSON.pretty_generate(@info))
          Log::SystemLog.info("update the scenario info file: %s" % location.address)
        end
      end

      # Return input location of the scenario. If the scenario doesn't have
      # input location, return nil.
      #
      # @return [BasicLocation]
      #   the input location
      def input
        input_location = @location + "input"
        return input_location.exist? ? input_location : nil
      end

      # Return list of input data location.
      #
      # @return [BasicLocation]
      #   input file locations
      def inputs
        info.inputs.map {|path| @location + path}
      end

      # Return the output location.
      #
      # @return [BasicLocation]
      #   the output location
      def output
        @location + "output"
      end

      # Return output file locations.
      #
      # @return [BasicLocation]
      #   output file locations
      def outputs
        @info.outputs.map {|path| @location + path}
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
  end
end
