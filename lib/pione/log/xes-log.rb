module Pione
  module Log
    # XESLog is a class for XES formatted log.
    class XESLog < ProcessLog
      set_format_name :xes

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

      # Format as a XML document.
      #
      # @return [String]
      #   result string
      def format(trace_filters=[])
        filter = Proc.new {|trace| trace_filters.empty? or trace_filters.any?{|filter| filter.call(trace)}}
        StringIO.new.tap do |out|
          XES::Document.new.tap do |doc|
            doc.log = XES::Log.default.tap do |log|
              log.concept_name = "PIONE process log"
              log.traces += [format_agent_activity + [format_rule_process, format_task_process]].flatten.select(&filter)
              log.traces.flatten!
            end
            if doc.formattable?
              doc.format.write(out, 2)
              return out.string
            else
              raise ProcessLogFormatError.new("not formattable: %s" % doc.inspect)
            end
          end
        end
      end

      private

      # Format agent activity records.
      #
      # @return [Array<XES::Trace>]
      def format_agent_activity
        @agent_activity_log.group_by(:agent_uuid).map do |agent_uuid, records|
          XES::Trace.new.tap do |trace|
            trace.attributes << XES.string("pione:traceType", "agent_activity")
            trace.identity_id = agent_uuid
            trace.events = records.sort{|a, b| a.timestamp <=> b.timestamp}.map do |record|
              XES::Event.new.tap do |event|
                event.concept_name = record.state
                event.org_resource = record.agent_type
                event.time_timestamp = record.timestamp
                event.lifecycle_transition = record.transition
              end
            end
          end
        end.flatten
      end

      # Format rule process records.
      #
      # @return [XES::Trace]
      def format_rule_process
        XES::Trace.new.tap do |trace|
          trace.concept_name = "rule_process %s" % Util::UUID.generate
          trace.attributes << XES.string("pione:traceType", "rule_process")
          trace.events = @rule_process_log.records.map do |record|
            XES::Event.new.tap do |event|
              # standard attributes
              event.concept_name = record.name
              event.org_resource = record.caller
              event.time_timestamp = record.timestamp
              event.lifecycle_transition = record.transition

              # pione extension attributes
              event.attributes << XES.string("pione:ruleType", record.rule_type)
            end
          end
        end
      end

      # Format task process records.
      #
      # @return [XES::Trace]
      def format_task_process
        XES::Trace.new.tap do |trace|
          trace.concept_name = "task process %s" % Util::UUID.generate
          trace.attributes << XES.string("pione:traceType", "task_process")
          trace.events = @task_process_log.records.map do |record|
            XES::Event.new.tap do |event|
              # standard attributes
              event.concept_name = record.name
              # event.org_resource = record.caller
              event.time_timestamp = record.timestamp
              event.lifecycle_transition = record.transition

              # pione extension attributes
              event.attributes << XES.string("pione:ruleType", record.rule_type)
              event.attributes << XES.string("pione:inputs", record.inputs)
              event.attributes << XES.string("pione:parameters", record.parameters)
            end
          end
        end
      end
    end
  end
end
