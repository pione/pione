module Pione
  module Command
    class ChildProcess < FrontOwner
      define_option('--caller-front uri') do |uri|
        @caller_front = DRbObject.new_with_uri(uri)
      end

      attr_reader :caller_front

      def validate_options
        abort("error: no caller front address") if @caller_front.nil?
      end

      def prepare
        @watchdog = Agent::TrivialRoutineWorker.new(Proc.new{ terminate if Process.ppid == 1 }, 3)
      end

      def start
        @watchdog.start
      end

      def terminate
        super
        @watchdog
      end
    end
  end
end
