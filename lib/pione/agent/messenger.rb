module Pione
  module Agent
    # Messenger is an agent for receiveing message logs.
    class Messenger < TupleSpaceClient
      set_agent_type :messenger, self

      # @param tuple_space [TupleSpace::TupleSpaceServer]
      #   tuple space
      # @param receiver [Log::MessageLogReceiver]
      #   message log receiver
      def initialize(tuple_space, receiver)
        super(tuple_space)

        # message log receiver
        @receiver = receiver
      end

      #
      # agent activities
      #

      define_transition :pass

      chain :init => :pass
      chain :pass => :pass

      #
      # transitions
      #

      # Transits to the state `pass`.
      def transit_to_pass
        tuples = take_all(TupleSpace::MessageTuple.any)
        tuples.sort{|a,b| a.timestamp <=> b.timestamp}.each do |tuple|
          tuple.contents.tap do |contents|
            (contents.kind_of?(String) ? [contents] : contents).each do |msg|
              @receiver.receive(msg, tuple.level, tuple.head, tuple.color)
            end
          end
        end
      end
    end
  end
end
