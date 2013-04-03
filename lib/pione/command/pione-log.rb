module Pione
  module Command
    class PioneLog < BasicCommand
      define_info do
        set_name "pione-log"
        set_banner "View and convert PIONE log."
      end

      define_option do
        default :action, :agent_log
        default :file, Pathname.new("log.txt")
        default :agent_type, "task_worker"

        option("--agent-log", "generate agent activity log") do |data|
          data[:action] = :agent_log
        end

        option("--agent-type=TYPE", "set agent type for agent log") do |data, type|
          data[:agent_type] = type
        end

        option("-f PATH", "--file=PATH", "set log file path") do |data, path|
          data[:file] = Pathname.new(path)
        end
      end

      start do
        case option[:action]
        when :agent_log
          Util::AgentXESLogFile.new(option[:file]).format(option[:agent_type]).write($stdout, 2)
          $stdout.flush
        end
      end
    end
  end
end
