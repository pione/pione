module Pione
  module Command
    # ChildProcess is a superclass for commands that are children of other
    # processes.
    class ChildProcess < FrontOwnerCommand
      define_option do
        define(:parent_front) do |item|
          item.long = '--parent-front=URI'
          item.desc = 'set parent front URI'
          item.default = false
          item.action = proc do |option, uri|
            option[:parent_front] = DRbObject.new_with_uri(uri)
          end
        end

        define(:no_parent) do |item|
          item.long = '--no-parent'
          item.desc = 'turn on no parent mode'
          item.default = false
          item.action = proc do |option|
            option[:no_parent_mode] = true
          end
        end

        # validate do |option|
        #   if not(option[:no_parent_mode]) and option[:parent_front].nil?
        #     abort("option error: no caller front address")
        #   end
        # end
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
