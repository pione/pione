module Pione
  module Agent
    module TupleSpaceClientOperation
      # Sends a bye message to the tuple space servers and terminate myself.
      def finalize
        unless current_state == :terminated
          bye
          terminate
        end
      end

      # Send a hello message to the tuple space server.
      def hello
        write(TupleSpace::AgentTuple.new(agent_type: agent_type, uuid: uuid))
      end

      # Send a bye message to the tuple space server.
      def bye
        Util.ignore_exception do
          take!(TupleSpace::AgentTuple.new(agent_type: agent_type, uuid: uuid))
        end
      end

      # Notify the agent happened a exception.
      def notify_exception(e)
        # ignore exception because the exception caused tuple server is down...
        Util.ignore_exception do
          write(TupleSpace::ExceptionTuple.new(uuid, agent_type, e))
        end
      end

      def base_location
        read(TupleSpace::BaseLocationTuple.any).location
      end

      # Protected take.
      def take(*args)
        tuple = super(*args, &method(:set_current_tuple_entry))
        set_current_tuple_entry(nil)
        return tuple
      end

      # Protected read.
      def read(*args)
        tuple = super(*args, &method(:set_current_tuple_entry))
        set_current_tuple_entry(nil)
        return tuple
      end

      private

      # Return current tuple's entry.
      def current_tuple_entry
        @__current_tuple_entry__
      end

      # Set current operating tuple entry.
      def set_current_tuple_entry(entry)
        @__current_tuple_entry__ = entry
        entry.instance_eval {if @place then def @place.to_s; ""; end; end }
      end

      # Cancel current tuple's entry.
      def cancel_current_tuple_entry
        current_tuple_entry.cancel if current_tuple_entry
      end
    end

    class TupleSpaceClient < BasicAgent
      include TupleSpace::TupleSpaceInterface
      include TupleSpaceClientOperation

      # Initialize agent's state.
      def initialize(tuple_space)
        super()
        set_tuple_space(tuple_space)
      end

      #
      # transitions
      #

      def transit_to_init
        hello
      end

      def transit_to_terminate
        Util.ignore_exception { bye }
        cancel_current_tuple_entry
      end

      #
      # helper methods
      #

      # Redefine hello method with logging.
      def hello
        record = Log::AgentConnectionProcessRecord.new.tap do |record|
          record.agent_type = agent_type
          record.agent_uuid = uuid
          record.message = "hello"
        end
        with_process_log(record) {super}
      end

      # Redefine bye method with logging.
      def bye
        record = Log::AgentConnectionProcessRecord.new.tap do |record|
          record.agent_type = agent_type
          record.agent_uuid = uuid
          record.message = "bye"
        end
        with_process_log(record) {super}
      end

      # Override call transition method with logging.
      def call_transition_method(*args)
        unless [:logger, :job_terminator, :messenger].include?(agent_type)
          record = Log::AgentActivityProcessRecord.new.tap do |rec|
            rec.agent_type = agent_type
            rec.agent_uuid = uuid
            rec.state = args.first
          end
          with_process_log(record) {super}
        else
          super
        end
      end
    end
  end
end
