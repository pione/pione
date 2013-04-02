module Pione
  module Command
    # ChildProcess is a superclass for commands that are children of other
    # processes.
    class ChildProcess < FrontOwnerCommand
      define_option do
        default :no_parent_front, false

        # --parent-front
        option('--parent-front=URI', 'set parent front URI') do |data, uri|
          data[:parent_front] = DRbObject.new_with_uri(uri)
        end

        # --no-parent
        option('--no-parent', 'turn on no parent mode') do |data|
          data[:no_parent_mode] = true
        end

        validate do |data|
          if not(data[:no_parent_mode]) and data[:parent_front].nil?
            abort("option error: no caller front address")
          end
        end
      end

      prepare do
        # "ppid == 1" means the parent is dead
        terminater = Proc.new do
          if Process.ppid == 1
            abort
            terminate
          end
          sleep 3
        end

        # watch that the parent process exists
        @watchdog = Agent::TrivialRoutineWorker.new(terminater)
      end

      start do
        @watchdog.start
      end

      terminate do
        # kill watchdog
        @watchdog.terminate
      end
    end
  end
end
