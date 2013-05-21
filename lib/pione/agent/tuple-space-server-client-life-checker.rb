module Pione
  module Agent
    class TupleSpaceServerClientLifeChecker < BasicAgent
      include TupleSpaceServerInterface

      define_state :checking_bye
      define_state :cleaning_agent
      define_state :sleeping

      define_state_transition :initialized => :checking_bye
      define_state_transition :checking_bye => :cleaning_agent
      define_state_transition :cleaning_agent => :checking_bye

      def initialize(tuple_space_server)
        super()
        set_tuple_space_server(tuple_space_server)
      end

      def transit_to_checking_bye
        return take(Tuple[:bye].any)
      end

      def transit_to_cleaning_agent(bye=nil)
        if bye
          take(Tuple[:agent].new(uuid: bye.uuid))
          return nil
        end
      end
    end
  end
end
