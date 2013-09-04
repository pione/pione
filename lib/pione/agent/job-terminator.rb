module Pione
  module Agent
    # JobTerminator is an agent that terminates the target agent when
    # "terminate" command is received.
    class JobTerminator < TupleSpaceClient
      set_agent_type :job_terminator, self

      def initialize(space, target)
        @target = target
        super(space)
      end

      #
      # transition definitions
      #

      define_transition :wait_command
      define_transition :do_command

      chain :init => :wait_command
      chain :wait_command => :do_command
      chain :do_command => :terminate

      #
      # transition methods
      #

      def transit_to_wait_command
        read(Tuple[:command].new(name: "terminate"))
      end

      def transit_to_do_command
        @target.terminate
      end
    end
  end
end
