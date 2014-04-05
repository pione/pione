module Pione
  module Front
    module NotificationRecipientInterface
      def set_recipient(recipient)
        @__recipient__ = recipient
      end

      # Notify the notification message to the recipient. This method is
      # non-blocking.
      #
      # @param message [Notification::Message]
      #   notification message
      # @return [void]
      def notify(message)
        non_blocking {@__recipient__.notify(message)}
      end
    end
  end
end
