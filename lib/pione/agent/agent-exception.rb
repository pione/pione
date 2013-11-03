module Pione
  module Agent
    # TerminationError is raised when the agent reaches trasition termination.
    class TerminationError < StandardError
      def initialize(agent, states)
        @agent = agent
        @states = states
      end

      def message
        "agent %s has reached termination([%s])" % [@agent, @states.map{|s| s.to_s}.join(", ")]
      end
    end

    # TimeoutError is raised when the agent is timeouted.
    class TimeoutError < StandardError
      attr_reader :agent        # agent timeouted
      attr_reader :agent_states # agent states
      attr_reader :sec          # timeout second

      def initialize(agent, states, sec)
        @agent = agent
        @states = states
        @sec = sec
      end

      def message
        sec = @sec ? "(%s sec)" % @sec : ""
        "%s timeouted %s at state [%s]" % [@agent, sec, @states.map{|s| s.to_s}.join(", ")]
      end
    end

    # ConnectionError is raised when agent is disconnected from other process unexpectedly.
    class ConnectionError < StandardError; end

    # TupleSpaceError is raised when tuple space is something bad.
    class TupleSpaceError < StandardError; end

    # Restart is raised when the agent should restart activity.
    class Restart < StandardError; end

    class UnknownInputGeneratorMethod
      def initialize(name)
        @name = name
      end

      def message
        "input generator method \"%s\" is unknown" % @name
      end
    end

    # JobError is raised when job ends because of something reasons.
    class JobError < StandardError
      def initialize(msg)
        @msg = msg
      end

      def message
        @msg
      end
    end
  end
end
