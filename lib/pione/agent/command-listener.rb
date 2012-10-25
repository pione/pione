module Pione
  module Agent
    class CommandListener < TupleSpaceClient
      set_agent_type :command_listener

      define_state :waiting_command
      define_state :doing_command

      define_state_transition :initialized => :waiting_command
      define_state_transition :waiting_command => :doing_command
      define_state_transition :doing_command => :waiting_command

      def initialize(ts_server, obj)
        @target = obj
        super(ts_server)
      end

      def transit_to_waiting_command
        return read(Tuple[:command].any)
      end

      def transit_to_doing_command(cmd)
        return unless cmd.kind_of?(Tuple::Command)
        case cmd.type
        when "terminate"
          @target.terminate
        end
      end
    end

    set_agent CommandListener
  end
end
