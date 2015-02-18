module Pione
  module Notification
    # TaskWorkerBrokerRecipient is a recipient for task worker broker agent.
    class TupleSpaceBrokerRecipient < Recipient
      # @param model [TaskWorkerBrokerModel]
      #   task worker broker model
      # @param front_uri [URI]
      #  URI of command front
      # @param listener_uri [URI]
      #   URI of notification listener
      def initialize(model, front_uri, listener_uri)
        super(front_uri, listener_uri)

        @model = model
        @lock = Mutex.new
      end

      # Receive a "tupele space" message.
      def receive_find_tuple_space_broker(message)
        front = DRb::DRbObject.new_with_uri(message["front"])
        front.notice_tuple_space_broker(@front_uri.to_s)
      end
    end
  end
end
