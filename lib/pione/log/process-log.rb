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

        # Return the named formatter class.
        #
        # @param name [Symbol]
        #   formatter name
        # @return [Class]
        #   formatter class
        def [](name)
          ProcessLog.instance_variable_get(:@format)[name]
        end

        # Read log files and return the process log.
        #
        # @param location [Location]
        #   path of process log file
        # @return [Hash{String => ProcessLog}]
        #   pairs of log id and the log
        def read(location)
          cache = location
          unless location.scheme == "local"
            cache = Location[Temppath.create]
            cache.create(location.read)
          end
          records = cache.path.each_line.map do |line|
            JSON.parse(line).inject({}) do |data, pair|
              data[pair[0].to_sym] = pair[1]
              data
            end.tap do |table|
              break ProcessRecord.build(table)
            end
          end
          group_by(:log_id, records).inject({}) do |table, pair|
            key, _records = pair
            table[key] = new(_records)
          end
        end

        # Set record filter.
        #
        # @yield block
        def set_filter(&block)
          @filter_block = block
        end

        attr_reader :filter_block

        # Return the record table grouped by the key.
        #
        # @return [Hash{String => Array<ProcessRecord>}]
        #   grouping records table
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
