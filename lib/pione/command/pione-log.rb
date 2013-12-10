module Pione
  module Command
    # PioneLog is a command for viewing PIONE log or converting into other formats.
    class PioneLog < BasicCommand
      #
      # basic informations
      #

      command_name "pione-log"
      command_banner "View and convert PIONE log."

      #
      # options
      #

      use_option :color
      use_option :debug

      option_default :trace_filter, []

      define_option(:agent_activity) do |item|
        item.long = "--agent-activity[=TYPE]"
        item.desc = "output only agent activity log"
        item.action = proc do |_, option, name|
          option[:trace_filter] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "agent_activity")) and
              (name.nil? or trace.events.first.org_resource == name)
          end
        end
      end

      define_option(:rule_process) do |item|
        item.long = "--rule-process"
        item.desc = "generate rule process log"
        item.action = proc do |_, option|
          option[:trace_filter] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "rule_process"))
          end
        end
      end

      define_option(:task_process) do |item|
        item.long = "--task-process"
        item.desc = "generate task process log"
        item.action = proc do |_, option|
          option[:trace_filter] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "task_process"))
          end
        end
      end

      define_option(:location) do |item|
        item.long = "--location=LOCATION"
        item.desc = "set log location of PIONE process"
        item.default = Location["local:./output/pione-process.log"]
        item.value = proc {|location| Location[location]}
      end

      define_option(:format) do |item|
        item.long = "--format=(XES|JSON|HTML)"
        item.desc = "set format type"
        item.default = :xes
        item.value = proc {|name| name.downcase.to_sym}
      end

      define_option(:log_id) do |item|
        item.long = "--log-id=ID"
        item.desc = "target log id"
      end

      validate_option do |option|
        unless option[:location].exist?
          abort("File not found in the location: %s" % option[:location].uri.to_s)
        end
      end

      #
      # command lifecycle: setup phase
      #

      setup :formatter
      setup :raw_log
      setup :log_id

      # Setup formatter.
      def setup_formatter
        if Log::ProcessLog.known?(option[:format])
          @formatter = Log::ProcessLog[option[:format]]
        else
          abort("Unknown format: %s" % option[:format])
        end
      end

      # Read raw log table.
      def setup_raw_log
        @raw_log_table = @formatter.read(option[:location])
      end

      def setup_log_id
        if option[:log_id]
          @log_id = option[:log_id]
        else
          @log_id = @raw_log_table.keys.sort.last
        end
      end

      #
      # command lifecycle: execution phase
      #

      execute :format_log

      # Format log file from the event log.
      def execute_format_log
        puts(@raw_log_table[@log_id].format(option[:trace_filter]))
      end
    end
  end
end
