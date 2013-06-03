module Pione
  module Agent
    class ProcessManager < TupleSpaceClient
      set_agent_type :process_manager

      define_state :running
      define_state_transition :initialized => :sleeping
      define_state_transition :sleeping => :running
      define_state_transition :running => :sleeping

      attr_reader :package

      def initialize(tuple_space_server, package, params, stream)
        raise ArgumentError unless package.find_rule("Main")
        super(tuple_space_server)
        @package = package
        @params = params
        @stream = stream
      end

      def transit_to_sleeping
        take(Tuple[:command].new("start-root-rule", nil))
      end

      def transit_to_running
        root = @package.create_root_rule(@package.find_rule("Main"), @params)
        if handler = root.make_handler(tuple_space_server)
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
