module Pione
  module Relay
    class Trampoline
      def initialize(uri, config)
        @obj = DRb::DRbObject.new_with_uri(uri)
        @protocol = TransmitterSocket.open_server(uri, config)
      end

      undef :to_s

      def method_missing(msg_id, *arg, &b)
        req_id = @protocol.send_request(@obj, msg_id, arg, b)
        @protocol.reader_thread
        succ, result = DRb.waiter_table.take(req_id, msg_id, arg)
        unless succ
          raise result
        end
        return result
      end
    end
  end
end
