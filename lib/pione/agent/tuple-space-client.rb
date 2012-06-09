require 'pione/common'

module Pione
  module Agent
    module TupleSpaceClientOperation
      # Send a bye message to the tuple space servers and terminate myself.
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
        write(to_bye_tuple)
      end

      # Convert a agent tuple.
      def to_agent_tuple
        Tuple[:agent].new(agent_type: agent_type, uuid: uuid)
      end

      # Convert a bye tuple
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

    class TupleSpaceClient < Base
      include TupleSpaceServerInterface
      include TupleSpaceClientOperation

      # Initialize agent's state.
      def initialize(ts_server)
        super()
        set_tuple_space_server(ts_server)
        unless self.kind_of?(CommandListener)
          @command_listener = CommandListener.new(ts_server, self)
        end
      end

      def start
        super()
        @command_listener.start if @command_listener
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
        @command_listener.terminate if @command_listener
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
        log do |msg|
          msg.add_record(agent_type, "action", "hello")
          msg.add_record(agent_type, "uuid", uuid)
        end
        super
      end

      # Redefine bye method with logging.
      def bye
        log do |msg|
          msg.add_record(agent_type, "action", "bye")
          msg.add_record(agent_type, "uuid", uuid)
        end
        super
      end

      # Redefine call transition method with logging.
      def call_transition_method(*args)
        unless agent_type == :logger
          log do |msg|
            msg.add_record(agent_type, "action", "transit")
            msg.add_record(agent_type, "state", args.first)
            msg.add_record(agent_type, "uuid", uuid)
          end
        end
        super
      end
    end
  end
end

require 'pione/agent/command-listener'
