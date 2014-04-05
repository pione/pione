module Pione
  module Notification
    # TaskWorkerBrokerRecipient is a recipient for task worker broker agent.
    class TaskWorkerBrokerRecipient < Recipient
      # @param model [TaskWorkerBrokerModel]
      #   task worker broker model
      # @param front_uri [URI]
      #  URI of command front
      # @param listener_uri [URI]
      #   URI of notification listener
      def initialize(model, front_uri, listener_uri)
        super(front_uri, listener_uri)

        @model = model
        @tuple_space = {}
        @lock = Mutex.new

        # update broker's tuple spaces
        @thread = Thread.new do
          while true
            sleep 1
            clean
            update_broker
          end
        end
      end

      # Terminate the recipient.
      def terminate
        super
        @thread.terminate
      end

      # Receive a "tupele space" message.
      def receive_tuple_space(message)
        uri = message["front"]
        if @tuple_space.has_key?(uri)
          @lock.synchronize {@tuple_space[uri][:last_time] = Time.now}
        else
          if tuple_space = get_tuple_space(uri)
            @lock.synchronize do
              @tuple_space[uri] = {:last_time => Time.now, :tuple_space => tuple_space}
            end
          end
        end
      end

      #
      # helper method
      #

      # Get a tuple space from front server at the URI.
      def get_tuple_space(uri)
        # build a reference to provider front
        front = DRb::DRbObject.new_with_uri(uri)

        # return the tuple space reference
        Timeout.timeout(3) {front.tuple_space}
      rescue Timeout::Error
        Log::Debug.notification do
          'tuple_space notfication ignored the provider "%s" that seems to be something bad' % front.uri
        end
      rescue DRb::DRbConnError, DRbPatch::ReplyReaderError => e
        Log::Debug.notification('The tuple space at "%s" disconnected: %s' % [front.uri, e.message])
      end

      # Clean tuple space table.
      def clean
        @lock.synchronize do
          now = Time.now
          dtime = Global.tuple_space_disconnection_time
          @tuple_space.delete_if {|_, holder| (now - holder[:last_time]) > dtime}
        end
      end

      # Update the tuple space list of broker.
      def update_broker
        @lock.synchronize do
          tuple_spaces = @tuple_space.values.map {|holder| holder[:tuple_space]}
          @model.update_tuple_spaces(tuple_spaces)
        end
      end
    end
  end
end
