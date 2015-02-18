module Pione
  module Agent
    # TupleSpaceTerminator is an agent that terminates tuple space's life.
    class TupleSpaceTerminator < TupleSpaceClient
      set_agent_type :tuple_space_terminator, self

      def initialize(tuple_space, &b)
        super(tuple_space)
        @action = b
      end

      #
      # transition definitions
      #

      define_transition :wait

      chain :init => :wait
      chain :wait => :terminate

      #
      # transition methods
      #

      def transit_to_wait
        read(TupleSpace::CommandTuple.new(name: "terminate-tuple-space"))
      end
    end
  end
end
