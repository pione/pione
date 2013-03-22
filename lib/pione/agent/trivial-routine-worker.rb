module Pione
  module Agent
    # TrivialRoutineWorker represents agent class for doing action periodly.
    class TrivialRoutineWorker < BasicAgent
      # state
      define_state :working

      # transition table
      define_state_transition :initialized => :working
      define_state_transition :working => :working

      # Create a trivial routine worker.
      #
      # @param action [Proc]
      #   worker's action as proc object
      def initialize(action)
        raise ArgumentError.new(action) unless action.kind_of?(Proc)
        @action = action
      end

      # Call the action.
      #
      # @return [void]
      def transit_to_working
        @action.call
      end
    end
  end
end
