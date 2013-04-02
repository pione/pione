module Pione
  module Util
    # Log is a class for logging on tuple space.
    class Log
      attr_accessor :timestamp

      # Creatas a new log record.
      #
      # @param component [String]
      #   component name
      # @param data
      #   log content
      def initialize(component, data)
        @component = component
        @timestample = nil
        @data = data
      end

      # Format as JSON string.
      #
      # @return [String]
      #   JSON string
      def format
        JSON.dump({:timestamp => @timestamp.iso8601(3), :component => @component}.merge(@data))
      end
    end

    class LogFile
      def initialize(path)
        @path = path
        @data = []
      end

      def read
        @path.readlines do |line|
          @data << JSON.parse(line)
        end
      end

      def group_by_uuid
        @data.inject({}) do |table, record|
          table.tap{|x| x[record["uuid"]] = d}
        end
      end
    end
  end
end
