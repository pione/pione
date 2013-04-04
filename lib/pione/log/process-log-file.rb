module Pione
  module Log
    # ProcessLogFile represents process log file.
    class ProcessLogFile
      class << self
        # Create a log file and read it.
        #
        # @return [ProcessLogFile]
        #   log object
        def read(path)
          new(path).tap{|x| x.read}
        end
      end

      # @return [Pathname]
      attr_reader :path

      # @return [Array<ProcessRcord>]
      attr_reader :records

      # Create a log file model object.
      #
      # @param path [Pathname]
      #   log file path
      def initialize(path)
        @path = path
        @records = []
      end

      # Read records from the path.
      #
      # @return [void]
      def read
        @path.each_line do |line|
          data = JSON.parse(line)
          component = data.delete("component")
          timestamp = data.delete("timestamp")
          @records << ProcessRecord.new(component, timestamp, data)
        end
      end

      # Return the hash table grouped by the key.
      #
      # @return [Hash{String => Array<ProcessRecord>}]
      #   grouping records table
      def group_by(key)
        @records.inject({}) do |table, record|
          table[record[key]] ||= []
          table.tap {|x| x[record[key]] << record}
        end
      end
    end
  end
end
