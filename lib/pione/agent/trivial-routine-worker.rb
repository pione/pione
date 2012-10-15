module Pione
  module Agent
    # TrivialRoutineWorker represents agent class for doing action periodly.
    class TrivialRoutineWorker < BasicAgent
      # state
      define_state :working
      define_state :sleeping

      # transition table
      define_state_transition :initialized => :working
      define_state_transition :working => :sleeping
      define_state_transition :sleeping => :working

      # Creates a worker.
      # @param [Proc] action
      #   worker's action as proc object
      # @param [Integer] sec
      #   sleeping time
      def initialize(action, sec)
        @action = action
        @sec = sec
      end

      # Calls the action.
      def transit_to_working
        @action.call
      end

      # Sleeps specified second.
      def transit_to_sleeping
        sleep @sec
      end
    end
  end
end
