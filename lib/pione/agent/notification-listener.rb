module Pione
  module Agent
    class NotificationListener < BasicAgent
      #
      # instance methods
      #

      # notification handler threads
      attr_reader :notification_handlers

      # @param model [NotificationListenerModel]
      #   notification-listner model
      # @param uri [URI]
      #   listening port
      def initialize(model, uri)
        super()
        @uri = uri
        @model = model
        @notification_handlers = ThreadGroup.new
        @lock = Mutex.new
      end

      #
      # agent activities
      #

      define_transition :receive

      chain :init => :receive
      chain :receive => :receive

      #
      # transitions
      #

      # Initialize the agent.
      def transit_to_init
        Log::SystemLog.info('Notification listener starts listening notification messages on "%s".' % @uri)
        @receiver = Notification::Receiver.new(@uri)
      end

      # Receive notification messages and make a message handler thread.
      def transit_to_receive
        # receive a notification
        transmitter_host, message = @receiver.receive

        # handle the notification in new thread
        thread = Util::FreeThreadGenerator.generate do
          handle_notification(transmitter_host, message)
        end
        @notification_handlers.add(thread)
      rescue StandardError => e
        Log::Debug.notification("Receiver agent has received bad data from %s, so it ignored and reopen socket." % ip_address)
        @receiver.reopen
      end

      # Close receiver socket.
      def transit_to_terminate
        # kill threads of notification handler
        @notification_handlers.list.each {|thread| thread.kill.join}
        # close socket
        @receiver.close unless @receiver.closed?
      end

      #
      # helper method
      #

      private

      # Notify the notification message to recipients.
      def handle_notification(transmitter_host, message)
        # notify the message to recepients
        bad_recipients = @model.recipients.each_with_object([]) do |uri, bad_recipients|
          begin
            Timeout.timeout(3) {DRb::DRbObject.new_with_uri(uri).notify(message)}
          rescue Timeout::Error, DRb::DRbConnError, DRbPatch::ReplyReaderError => e
            Log::Debug.notification("Notification recipient %s disconnected: %s" % [uri, e.message])
            bad_recipients << uri
          end
        end

        # delete bad recipients
        @model.delete_recipient(*bad_recipients)
      end
    end
  end
end
