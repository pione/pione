module Pione
  module Log
    # ProcessLog represents process log records of PIONE.
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
        # @return [ProcessLogFile]
        #   log object
        def read(location)
          if location.file?
            read_file(location)
          else
            read_directory(location)
          end
        end

        # Set record filter.
        #
        # @yield block
        def set_filter(&block)
          @filter_block = block
        end

        attr_reader :filter_block

        private

        # Read records from the log file at the location.
        #
        # @param location [Location::BasicLocation]
        #   log location
        def read_file(location)
          cache = Location[Temppath.create]
          cache.create(location.read)
          cache.path.each_line.map do |line|
            JSON.parse(line).inject({}) do |data, pair|
              data[pair[0].to_sym] = pair[1]
              data
            end.tap do |table|
              break ProcessRecord.build(table)
            end
          end.tap do |records|
            break new([ProcessLogBundle.new(records)])
          end
        end

        # Read records from log files in directory at the location.
        #
        # @param location [Location::BasicLocation]
        #   log directory location
        def read_directory(location)
          location.file_entries.inject(new([])) do |formatter, entry|
            if /pione_\d{14}\.log/.match(entry.path.basename.to_s)
              new(formatter.bundles + read_file(entry).bundles)
            else
              formatter
            end
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
        @records = records.select {|record| self.class.filter_block.call(record)}
      end

      # Return the record table grouped by the key.
      #
      # @return [Hash{String => Array<ProcessRecord>}]
      #   grouping records table
      def group_by(key)
        @records.inject({}) do |table, record|
          table[record.send(key)] ||= []
          table.tap {|x| x[record.send(key)] << record}
        end
      end
    end

    # ProcessLogFormatter is a basic class for fomatting process logs.
    class ProcessLogFormatter < ProcessLog
      # @return [Array<ProcessBunle>]
      #   target logs that we format
      attr_reader :bundles

      # @param bundles [Array<ProcessLogBundle>]
      #   log bundles
      def initialize(bundles)
        @bundles = bundles
      end

      # Format bundle logs.
      #
      # @return [String]
      #   result string
      def format(trace_filters=[])
        raise NotImplementedError
      end
    end

    # ProcessLogFormatError is raised when formatter cannot format some objects.
    class ProcessLogFormatError < StandardError
      # @param object [Object]
      #   the object that we cannnot format
      def initialize(object)
        @object = object
      end

      # @api private
      def message
        "not formattable: %s" % @object.inspect
      end
    end

    # ProcessLogBundle is a bundle of raw logs.
    class ProcessLogBundle
      attr_reader :agent_activity_log
      attr_reader :rule_process_log
      attr_reader :task_process_log

      # @param records [Array<ProcessRecord>]
      #   log records
      def initialize(records)
        @agent_activity_log = AgentActivityLog.new(records)
        @rule_process_log = RuleProcessLog.new(records)
        @task_process_log = TaskProcessLog.new(records)
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
