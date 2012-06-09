require 'pione/common'

module Pione
  module Agent
    class TupleSpaceServerLifeKeeper < Base
      set_agent_type :tuple_space_server_life_keeper

      define_state :updating_lifetime
      define_state :sleeping

      define_state_transition :initialized => :updating_lifetime
      define_state_transition :updating_lifetime => :sleeping
      define_state_transition :sleeping => :updating_lifetime

      def initialize(ts_server)
        @ts_server = ts_server
        super()
      end

      # Return the server's provider.
      def provider
        TupleSpaceProvider.instance(@provider_options)
      end

      def transit_to_updating_lifetime
        provider.add(@ts_server)
        return nil
      end

      def transit_to_sleeping
        sleep 1
        return nil
      end
    end
  end
end
