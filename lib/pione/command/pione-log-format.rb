module Pione
  module Command
    # `PioneLogFormat` is a command that converts PIONE raw log into XES or
    # other formats.
    class PioneLogFormat < BasicCommand
      #
      # basic informations
      #

      define(:name, "format")
      define(:desc, "Convert PIONE raw log into XES or other formats")

      #
      # arguments
      #

      argument PioneLogArgument.log_location

      #
      # options
      #

      option_pre(:prepare_model) do |item|
        item.process do
          model[:trace_types] = []
          model[:agent_types] = []
        end
      end

      option CommonOption.color
      option CommonOption.debug

      option(:trace_types) do |item|
        item.type = :string
        item.long = "--trace-type"
        item.arg  = "NAME"
        item.desc = 'Output only the trace type: "agent", "rule", or "task"'

        item.process {|val| model[:trace_types] << val}
      end

      option(:agent_types) do |item|
        item.type = :string
        item.arg  = "NAME"
        item.long = "--agent-type"
        item.desc = 'Output only the agent type: "task_worker", "input_generator", ...'

        item.process {|val| model[:agent_types] << val}
      end

      option(:format) do |item|
        item.type  = :symbol_downcase
        item.range = [:xes, :json, :xml]
        item.long  = "--format"
        item.arg   = "NAME"
        item.desc  = 'Set format type'
        item.init  = :xes
      end

      option(:log_id) do |item|
        item.type = :string
        item.long = "--log-id"
        item.arg  = "ID"
        item.desc = "Target log ID"
      end

      #
      # command lifecycle: setup phase
      #

      phase(:setup) do |seq|
        seq << :trace_filters
        seq << :formatter
        seq << :raw_log
      end

      setup(:trace_filters) do |item|
        item.desc = "Setup trace filters"

        item.assign(:trace_filters) do
          Array.new
        end

        # agent filters
        item.process do
          test(model[:trace_types].include?("agent"))

          if model[:agent_types].empty?
            model[:trace_filters] << Proc.new do |trace|
              trace.attributes.include?(XES.string("pione:traceType", "agent_activity"))
            end
          else
            model[:trace_filters] << Proc.new do |trace|
              trace.attributes.include?(XES.string("pione:traceType", "agent_activity")) and
                model[:agent_types].include?(trace.events.first.org_resource)
            end
          end
        end

        # rule filters
        item.process do
          test(model[:trace_types].include?("rule"))

          model[:trace_filters] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "rule_process"))
          end
        end

        # task filters
        item.process do
          test(model[:trace_types].include?("task"))

          model[:trace_filters] << Proc.new do |trace|
            trace.attributes.include?(XES.string("pione:traceType", "task_process"))
          end
        end
      end

      setup(:formatter) do |item|
        item.desc = "Setup formatter"

        item.assign(:formatter) do
          if Log::ProcessLog.known?(model[:format])
            Log::ProcessLog[model[:format]]
          else
            cmd.abort("Unknown format: %s" % model[:format])
          end
        end
      end

      setup(:raw_log) do |item|
        item.desc = "Read raw log table"

        item.assign(:raw_log_table) do
          model[:formatter].read(model[:log_location])
        end

        item.assign(:log_id) do
          test(not(model[:log_id]))
          model[:raw_log_table].keys.sort.last
        end
      end

      #
      # command lifecycle: execution phase
      #

      phase(:execution) do |item|
        item << :format_log
      end

      execution(:format_log) do |item|
        item.desc = "Format log file from the event log"

        item.process do
          puts(model[:raw_log_table][model[:log_id]].format(model[:trace_filters]))
        end
      end
    end

    PioneLog.define_subcommand("format", PioneLogFormat)
  end
end
