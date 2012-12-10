module Pione
  module Agent
    class CommandListener < TupleSpaceClient
      set_agent_type :command_listener

      define_state :waiting_command
      define_state :doing_command

      define_state_transition :initialized => :waiting_command
      define_state_transition :waiting_command => :doing_command
      define_state_transition :doing_command => :waiting_command

      define_exception_handler Exception => :error

      def hello
      end

      def bye
      end

      def initialize(tuple_space_server, target)
        @target = target
        super(tuple_space_server)
      end

      def transit_to_waiting_command
        return read(Tuple[:command].any)
      end

      def transit_to_doing_command(cmd=nil)
        return unless cmd # the case we got null command
        return unless cmd.kind_of?(Tuple::Command)
        case cmd.type
        when "terminate"
          @target.terminate
          terminate
        end
      end

      def transit_to_error(e)
        terminate
      end
    end

    set_agent CommandListener
  end
end
