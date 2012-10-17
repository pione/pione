module Pione
  module Agent
    class ProcessManager < BasicAgent
      set_agent_type :process_manager

      define_state :running
      define_state_transition :initialized => :running
      define_state_transition :running => :sleeping
      define_state_transition :sleeping => :running

      attr_reader :document

      def initialize(tuple_space_server, document, params)
        raise ArgumentError unless document.main
        super()
        @tuple_space_server = tuple_space_server
        @document = document
        @params = params
      end

      def transit_to_running
        if handler = @document.root_rule(@params).make_handler(@tuple_space_server)
          handler.handle
        else
          user_message "no inputs"
          terminate
        end
        terminate unless @stream
      end

      def transit_to_sleeping
        sleep 5
      end
    end

    set_agent ProcessManager
  end
end
