module Pione
  module Front
    # `NotificationListenerFront` is a front interface for
    # `pione-notification-listener` command.
    class NotificationListenerFront < BasicFront
      def initialize(cmd)
        super(cmd, Global.notification_listener_front_port)
      end

      # Add the recipient that receives notification messages.
      #
      # @param uri [String]
      #   URI of the recipent's front
      # @param recipient [Notification::Recipient]
      #   the recipient that receives notification messages
      # @return [void]
      def add(uri)
        non_blocking do
          @cmd.model.add_recipient(uri)
          Log::SystemLog.debug 'Recipient "%s" has been added.' % uri
        end
      end

      # Delete the recipient that receives notification messages.
      #
      # @param uri [String]
      #   URI of the recipent's front
      def delete(uri)
        non_blocking do
          @cmd.model.delete_recipient(uri)
          Log::SystemLog.debug 'Recipient "%s" has been deleted.' % uri
        end
      end
    end
  end
end
