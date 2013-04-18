module Pione
  module Command
    # PioneLog is a command for viewing PIONE log or converting into other formats.
    class PioneLog < BasicCommand
      define_info do
        set_name "pione-log"
        set_banner "View and convert PIONE log."
      end

      define_option do
        default :format, :xes
        default :trace_filter, []
        default :output, Location["local:./output"]

        option("--agent-activity[=TYPE]", "output only agent activity log") do |data, name|
          data[:trace_filter] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "agent_activity")) and
              (name.nil? or trace.events.first.org_resource == name)
          end
        end

        option("--rule-process", "generate rule process log") do |data|
          data[:trace_filter] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "rule_process"))
          end
        end

        option("--task-process", "generate task process log") do |data|
          data[:trace_filter] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "task_process"))
          end
        end

        option("--location=LOCATION", "set log location of PIONE process") do |data, location|
          data[:output] = Location[location]
        end

        option("--format=(XES|JSON|HTML)", "set format type") do |data, name|
          data[:format] = name.downcase.to_sym
        end

        validate do |data|
          unless data[:output].exist?
            abort("File or directory not found in the location: %s" % data[:output].uri.to_s)
          end
        end
      end

      start do
        Log::ProcessLog[option[:format]].tap do |formatter|
          if formatter
            $stdout.puts(formatter.read(option[:output]).format(option[:trace_filter]))
            $stdout.flush
          else
            abort("Unknown format: %s" % option[:format])
          end
        end
      end
    end
  end
end
