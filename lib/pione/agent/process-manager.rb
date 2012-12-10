module Pione
  module Agent
    class ProcessManager < TupleSpaceClient
      set_agent_type :process_manager

      define_state :running
      define_state_transition :initialized => :sleeping
      define_state_transition :sleeping => :running
      define_state_transition :running => :sleeping

      attr_reader :document

      def initialize(tuple_space_server, document, params, stream)
        raise ArgumentError unless document.main
        super(tuple_space_server)
        @document = document
        @params = params
        @stream = stream
      end

      def transit_to_sleeping
        take(Tuple[:command].new("start-root-rule", nil))
      end

      def transit_to_running
        if handler = @document.root_rule(@params).make_handler(tuple_space_server)
          handler.handle
        else
          user_message "error: no inputs"
          terminate
        end
        terminate unless @stream
      end
    end

    set_agent ProcessManager
  end
end
