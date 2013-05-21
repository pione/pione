module Pione
  module Agent
    # Messenger is an agent for receiveing message logs.
    class Messenger < TupleSpaceClient
      set_agent_type :messenger

      # Create a messenger agent.
      #
      # @param tuple_space_server [TupleSpaceServer]
      #   tuple space server
      def initialize(tuple_space_server)
        super(tuple_space_server)
        @buffer = []
      end

      define_state :initialized
      define_state :print
      define_state :terminated

      define_state_transition :initialized => :print
      define_state_transition :print => :print

      # Transits to the state +print+.
      def transit_to_print
        tuples = take_all(Tuple[:message].any)
        tuples.sort{|a,b| a.timestamp <=> b.timestamp}.each do |tuple|
          msgs = tuple.contents
          msgs = [msgs] if tuple.contents.kind_of?(String)
          msgs.each do |msg|
            puts "%s%s %s" % ["  "*tuple.level, ("%5s" % tuple.head).color(tuple.color), msg]
          end
        end
      end
    end

    set_agent Messenger
  end
end
