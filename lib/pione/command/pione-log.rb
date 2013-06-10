module Pione
  module Command
    # PioneLog is a command for viewing PIONE log or converting into other formats.
    class PioneLog < BasicCommand
      define_info do
        set_name "pione-log"
        set_banner "View and convert PIONE log."
      end

      define_option do
        use Option::CommonOption.debug
        use Option::CommonOption.color

        default :trace_filter, []

        define(:agent_activity) do |item|
          item.long = "--agent-activity[=TYPE]"
          item.desc = "output only agent activity log"
          item.action = proc do |option, name|
            option[:trace_filter] << Proc.new do |trace|
              trace.attributes.include?(XES.string("pione:traceType", "agent_activity")) and
                (name.nil? or trace.events.first.org_resource == name)
            end
          end
        end

        define(:rule_process) do |item|
          item.long = "--rule-process"
          item.desc = "generate rule process log"
          item.action = proc do |option|
            option[:trace_filter] << Proc.new do |trace|
              trace.attributes.include?(XES.string("pione:traceType", "rule_process"))
            end
          end
        end

        define(:task_process) do |item|
          item.long = "--task-process"
          item.desc = "generate task process log"
          item.action = proc do |option|
            option[:trace_filter] << Proc.new do |trace|
              trace.attributes.include?(XES.string("pione:traceType", "task_process"))
            end
          end
        end

        define(:location) do |item|
          item.long = "--location=LOCATION"
          item.desc = "set log location of PIONE process"
          item.default = Location["local:./output/pione-process.log"]
          item.value = proc {|location| Location[location]}
        end

        define(:format) do |item|
          item.long = "--format=(XES|JSON|HTML)"
          item.desc = "set format type"
          item.default = :xes
          item.value = proc {|name| name.downcase.to_sym}
        end

        validate do |option|
          unless option[:location].exist?
            abort("File not found in the location: %s" % option[:location].uri.to_s)
          end
        end
      end

      start do
        Log::ProcessLog[option[:format]].tap do |formatter|
          if formatter
            $stdout.puts(formatter.read(option[:location]).format(option[:trace_filter]))
            $stdout.flush
          else
            abort("Unknown format: %s" % option[:format])
          end
        end
      end
    end
  end
end
