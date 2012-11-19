module Pione
  module Command
    class ChildProcess < FrontOwnerCommand
      use_option_module CommandOption::ChildProcessOption
      attr_reader :parent_front

      # @api private
      def validate_options
        if not(@no_parent_mode) and @parent_front.nil?
          abort("error: no caller front address")
        end
      end

      # @api private
      def prepare
        super

        # "ppid == 1" means the parent is dead
        terminater = Proc.new do
          terminate if Process.ppid == 1
          sleep 3
        end

        # watch that the parent process exists
        @watchdog = Agent::TrivialRoutineWorker.new(terminater)
      end

      # @api private
      def start
        @watchdog.start
      end

      def terminate
        @watchdog.terminate
        super
      end
    end
  end
end
