module Pione
  module Agent
    class Aborting < Exception; end

    # TransitionError happens when
    class TransitionError < StandardError; end

    # TimeoutStateWaiting happens when not reached expected in time.
    class TimeoutStateWaiting < StandardError
      # expected status
      attr_reader :expected

      # current status
      attr_reader :current

      # Creates an exception.
      #
      # @param [Symbol] expected
      #   expected state
      # @param [Symbol] current
      #   current state
      def initialize(expected, current)
        @expected = expected
        @current = current
      end

      # @private
      def message
        msg = "expected state is '%s' but current state is '%s'"
        msg % [@expected_state, @current_state]
      end
    end
  end
end
