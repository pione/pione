module Pione
  module Notification
    # Recipient is a wrapper for notification recipients. This wraps a command
    # and notifies messages to it when a notification listener receives
    # notifications. Recipients should be registerd to listner periodically
    # because the listener forgets recipients after some minites. Note that
    # `Recipient` instance is registered to a listener after it is created
    # immediately, so the listener is launched up to that time.
    class Recipient
      # @param front_uri [URI]
      #   URI of command front that receives messages
      # @param listener_uri [URI]
      #   URI of notification listener
      def initialize(front_uri, listener_uri)
        @listener_uri = listener_uri
        @front_uri = front_uri
        @__listener_thread__ = keep_connection
        @__connection__ = false
      end

      # Notify the message. This is a non-blocking method.
      def notify(message)
        name = ("receive_%s" % message.type).downcase
        if respond_to?(name)
          __send__(name, message)
        end
      end

      def terminate
        @__listerner_thread__.terminate if @__listener_thread__.alive?
        disconnect
      end

      private

      # Keep the listener connection. This is non-blocking.
      #
      # @return [Thread]
      #   a keeping thread
      def keep_connection
        Thread.new do
          loop do
            begin
              listener = DRb::DRbObject.new_with_uri(@listener_uri)
              listener.add(@front_uri.to_s)

              unless @__connection__
                Log::SystemLog.info('Notification recipient has connected to the listener "%s".' % @listener_uri)
              end
              @__connection__ = true
            rescue Object => e
              Log::SystemLog.warn('Notification recipient has failed to connect the listener "%s": %s' % [@listener_uri, e.message])
            ensure
              sleep 5
            end
          end
        end
      end

      def disconnect
        Util.ignore_exception do
          listener = DRb::DRbObject.new_with_uri(@listener_uri)
          listener.delete(@front_uri.to_s)
        end
      end
    end
  end
end
