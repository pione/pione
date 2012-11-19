module Pione
  module Agent
    # TrivialRoutineWorker represents agent class for doing action periodly.
    class TrivialRoutineWorker < BasicAgent
      # state
      define_state :working

      # transition table
      define_state_transition :initialized => :working
      define_state_transition :working => :working

      # Creates a worker.
      # @param [Proc] action
      #   worker's action as proc object
      # @param [Integer] sec
      #   sleeping time
      def initialize(action)
        raise ArgumentError.new(action) unless action.kind_of?(Proc)
        @action = action
      end

      # Calls the action.
      def transit_to_working
        @action.call
      end
    end
  end
end
