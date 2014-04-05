module Pione
  module Model
    # NotificationListenerModel is a model for pione-notification-listener. This
    # manages recipiants lifecycle.
    class NotificationListenerModel < Rootage::Model
      attr_reader :recipients

      def initialize
        super
        @recipients = []
        @lock = Mutex.new
      end

      # Add the URI of recipient.
      def add_recipient(uri)
        @lock.synchronize do
          unless @recipients.include?(uri)
            @recipients << uri
          end
        end
      end

      # Delete the recipients.
      def delete_recipient(*uris)
        @lock.synchronize {uris.each {|uri| @recipients.delete(uri)}}
      end
    end
  end
end
