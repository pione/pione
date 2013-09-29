module Pione
  module Agent
    # JobTerminator is an agent that terminates the target agent when
    # "terminate" command is received.
    class JobTerminator < TupleSpaceClient
      set_agent_type :job_terminator, self

      def initialize(space, &b)
        super(space)
        @action = b
      end

      #
      # transition definitions
      #

      define_transition :wait
      define_transition :fire

      chain :init => :wait
      chain :wait => :fire
      chain :fire => :terminate

      #
      # transition methods
      #

      def transit_to_wait
        read(TupleSpace::CommandTuple.new(name: "terminate"))
      end

      def transit_to_fire
        Log::Debug.system("job terminator fires the action %s." % @action)
        @action.call
      end
    end
  end
end
