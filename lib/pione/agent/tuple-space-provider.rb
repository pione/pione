module Pione
  module Agent
    # TupleSpaceProvider is an agent that provides a URI of tuple space as
    # notification messages.
    class TupleSpaceProvider < BasicAgent
      set_agent_type :tuple_space_provider, self

      #
      # instance methods
      #

      # @param provider [URI]
      #   URI of the tuple space
      # @param targets [Array<URI>]
      #   target URIs
      def initialize(uri, targets=Global.notification_targets)
        super()
        @targets = targets
        @notification = Notification::Message.new(
          "TUPLE_SPACE_PROVIDER", "TUPLE_SPACE", {"front" => uri}
        )
      end

      #
      # agent activities
      #

      define_transition :send_message
      define_transition :sleep

      chain :init => :send_message
      chain :send_message => :sleep
      chain :sleep => :send_message

      #
      # transitions
      #

      def transit_to_send_message
        Notification::Transmitter.transmit(@notification, @targets)
      end

      def transit_to_sleep
        sleep 5
      end
    end
  end
end
