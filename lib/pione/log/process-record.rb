module Pione
  module Log
    # ProcessRecord is a class that represents records of process log. Records
    # are in tuple spaces and handled by PIONE's logger agent.
    class ProcessRecord
      # @return [String]
      attr_accessor :component

      # @return [Time]
      attr_accessor :timestamp

      # @return [Hash]
      attr_reader :data

      forward :@data, :[], :[]=

      # Creates a new process log record.
      #
      # @param component [String]
      #   component name
      # @param data [Hash{String => Object}]
      #   log content
      def initialize(component, timestamp, data)
        @component = component
        if timestamp
          @timestamp = timestamp.kind_of?(Time) ? timestamp : Time.parse(timestamp)
        end
        @data = data
      end

      def [](key)
        case key
        when "component"
          @component
        when "timestamp"
          @timestamp
        else
          @data[key]
        end
      end

      def []=(key, val)
        case key
        when "component"
          @component = val
        when "timestamp"
          @timestamp = val
        else
          @data[key] = val
        end
      end

      # Format as JSON string.
      #
      # @return [String]
      #   JSON string
      def format
        base = {:timestamp => @timestamp.iso8601(3), :component => @component}
        JSON.dump(base.merge(@data))
      end
    end
  end
end
