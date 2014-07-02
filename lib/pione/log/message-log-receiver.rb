module Pione
  module Log
    # MessageLogReceiver is an abstract class for message log receivers.
    class MessageLogReceiver
      # Receive the message with attributes.
      #
      # @param message [String]
      #   the message
      # @param level [Integer]
      #   message depth level
      # @param header [String]
      #   message header
      # @param color [String]
      #   message color
      # @param session_id [String]
      #   session_id
      def receiver(message, level, header, color, session_id)
        raise NotImplementedError.new
      end
    end

    # `CUIMessageLogReceiver` is a message log receiver for CUI
    # environment. This receiver prints messages to stdout.
    class CUIMessageLogReceiver < MessageLogReceiver
      def initialize(out=$stdout)
        @out = out
      end

      def receive(message, level, header, color, session_id)
        @out.puts "%s%s %s" % ["  "*level, ("%5s" % header).color(color), message]
      end
    end
  end
end
