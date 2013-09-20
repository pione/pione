module Pione
  module Log
    # ProcessLog represents process log file.
    class ProcessLog
      # formatter table
      @format = {}

      class << self
        # Set formatter name of this class.
        #
        # @param name [Symbol]
        #   formatter name
        # @return [void]
        def set_format_name(name)
          ProcessLog.instance_variable_get(:@format)[name] = self
        end

        # Return true if the formatter name is known.
        def known?(name)
          ProcessLog.instance_variable_get(:@format).has_key?(name)
        end

        # Return the named formatter class.
        def [](name)
          ProcessLog.instance_variable_get(:@format)[name]
        end

        # Read the raw log file and return the process log table grouped by log id.
        def read(location)
          # create local cache of raw log for performance
          cache = location
          unless location.scheme == "local"
            cache = Location[Temppath.create]
            cache.create(location.read)
          end

          # read all records
          records = cache.path.each_line.map do |line|
            JSON.parse(line).inject({}) do |data, (key, val)|
              data.tap {data[key.to_sym] = val}
            end.tap {|data| break ProcessRecord.build(data)}
          end

          # group records by log id
          group_by(:log_id, records).inject({}) do |table, (key, _records)|
            table.tap {table[key] = new(_records)}
          end
        end

        # Set record filter.
        def set_filter(&block)
          @filter_block = block
        end

        attr_reader :filter_block

        # Return the record table grouped by the key.
        def group_by(key, records)
          records.inject({}) do |table, record|
            table[record.send(key)] ||= []
            table.tap {|x| x[record.send(key)] << record}
          end
        end
      end

      forward :@records, :map

      # @return [Array<ProcessRcord>]
      #   records of the log
      attr_reader :records

      # @param records [Array<ProcessRecord>]
      #   log records
      def initialize(records)
        @records = records.select do |record|
          if block = self.class.filter_block
            block.call(record)
          else
            true
          end
        end
      end

      # Return the record table grouped by the key.
      #
      # @return [Hash{String => Array<ProcessRecord>}]
      #   grouping records table
      def group_by(key)
        self.class.group_by(key, @records)
      end

      # Format records.
      #
      # @return [String]
      #   result string
      def format(trace_filters=[])
        raise NotImplementedError
      end
    end

    # AgentActivityLog is a set of records written about agent activities.
    class AgentActivityLog < ProcessLog
      set_filter {|record| record.type == :agent_activity}
    end

    # RuleProcessLog is a set of records written about details of rule process.
    class RuleProcessLog < ProcessLog
      set_filter {|record| record.type == :rule_process}
    end

    # TaskProcessLog is a set of records written about details of task process.
    class TaskProcessLog < ProcessLog
      set_filter {|record| record.type == :task_process}
    end
  end
end
