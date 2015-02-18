module Pione
  module Front
    # TupleSpaceBrokerFront is a front interface for pione-tuple-space-broker
    # command.
    class TupleSpaceBrokerFront < BasicFront
      # this receives notification messages
      include NotificationRecipientInterface

      def initialize(cmd)
        super(cmd, Global.tuple_space_broker_front_port_range)
        set_recipient(Notification::TupleSpaceBrokerRecipient.new(cmd, uri, Global.notification_listener))
      end

      def create()
        @cmd.model[:tuple_space_manager].create()
      end

      def close_tuple_space(tuple_space_id)
        @cmd.model[:tuple_space_manager].close_tuple_space(tuple_space_id)
      end
    end
  end
end
