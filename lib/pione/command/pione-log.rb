module Pione
  module Command
    # PioneLog is a command for viewing PIONE log or converting into other formats.
    class PioneLog < BasicCommand
      define_info do
        set_name "pione-log"
        set_banner "View and convert PIONE log."
      end

      define_option do
        default :file, Pathname.new("log.txt")
        default :agent_type, "task_worker"

        option("--agent-log", "generate agent activity log") do |data|
          data[:action] = :agent_log
        end

        option("--rule-process-log", "generate rule process log") do |data|
          data[:action] = :rule_process_log
        end

        option("--agent-type=TYPE", "set agent type for agent log") do |data, type|
          data[:agent_type] = type
        end

        option("-f PATH", "--file=PATH", "set log file path") do |data, path|
          data[:file] = Pathname.new(path)
        end

        validate do |data|
          if data[:action].nil?
            puts "should specify --agent-log or --rule-process-log"
          end
        end
      end

      start do
        log_file = Log::ProcessLogFile.read(option[:file])
        case option[:action]
        when :agent_log
          Log::AgentXESFormatter.new(log_file, option[:agent_type]).format.write($stdout, 2)
          $stdout.flush
        when :rule_process_log
          Log::RuleProcessXESFormatter.new(log_file).format.write($stdout, 2)
          $stdout.flush
        end
      end
    end
  end
end
