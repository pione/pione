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
        write(to_agent_tuple)
      end

      # Send a bye message to the tuple space server.
      def bye
        Util.ignore_exception do
          write(to_bye_tuple)
        end
      end

      # Makes the agent tuple.
      # @return [Tuple::Agent]
      #   the agent tuple
      def to_agent_tuple
        Tuple[:agent].new(agent_type: agent_type, uuid: uuid)
      end

      # Makes the bye tuple.
      # @return [Tuple::Bye]
      #   the bye tuple
      def to_bye_tuple
        Tuple[:bye].new(agent_type: agent_type, uuid: uuid)
      end

      # Notify the agent happened a exception.
      def notify_exception(e)
        # ignore exception because the exception caused tuple server is down...
        Util.ignore_exception do
          write(Tuple[:exception].new(uuid, agent_type, e))
        end
      end

      def base_location
        read(Tuple[:base_location].any).location
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
      include TupleSpaceServerInterface
      include TupleSpaceClientOperation

      # Initialize agent's state.
      def initialize(tuple_space_server)
        super()
        set_tuple_space_server(tuple_space_server)
      end

      def start
        super()
        return self
      end

      # State initialized.
      def transit_to_initialized
        hello
      end

      # State terminated
      def transit_to_terminated
        Util.ignore_exception { bye }
        cancel_current_tuple_entry
      end

      # State error
      def transit_to_error(e)
        if e
          $stderr.puts e
          $stderr.puts e.backtrace
        end
        notify_exception(e)
        terminate
      end

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
        unless [:logger, :command_listener].include?(agent_type)
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
