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
          records = path.each_line.inject([]) do |records, line|
            data = JSON.parse(line)
            component = data.delete("component")
            timestamp = data.delete("timestamp")
            records << ProcessRecord.new(component, timestamp, data)
          end
          new(records)
        end
      end

      forward! :@records, :map

      # @return [Array<ProcessRcord>]
      attr_reader :records

      # Create a log model object.
      #
      # @param records [Pathname]
      #   records of log file
      def initialize(records)
        @records = records
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

      def select(&b)
        self.class.new(@records.select(&b))
      end
    end
  end
end
