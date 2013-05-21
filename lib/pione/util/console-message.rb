module Pione
  module Util
    # ConsoleMessage is a set of utility methods for sending messages to user.
    module ConsoleMessage
      # @api private
      MESSAGE_QUEUE = Queue.new

      # Message queue thread
      Thread.new {
        while msg = MESSAGE_QUEUE.pop
          puts msg
        end
      }

      # @!group Message Mode

      # @api private
      @@debug_mode = false

      # @api private
      @@quiet_mode = false

      # Evaluate the block in debug mode.
      #
      # @yield []
      #   target block
      # @return [void]
      def debug_mode
        orig = @@debug_mode
        @@debug_mode = true
        yield
        @@debug_mode = orig
      end
      module_function :debug_mode

      # Set debug mode.
      #
      # @param [bool] mode
      #   flag of debug mode
      # @return [void]
      def debug_mode=(mode)
        @@debug_mode = mode
      end
      module_function :"debug_mode="

      # Return true if the system is debug mode.
      #
      # @return [bool]
      def debug_mode?
        @@debug_mode
      end
      module_function :debug_mode?

      # Evaluate the block in quiet mode.
      #
      # @yield []
      #   target block
      # @return [void]
      def quiet_mode
        orig = @@quiet_mode
        @@quiet_mode = true
        yield
        @@quiet_mode = orig
      end
      module_function :quiet_mode

      # Set quiet mode.
      #
      # @param [bool] mode
      #   flag of quiet mode
      # @return [void]
      def quiet_mode=(mode)
        @@quiet_mode = mode
      end
      module_function :"quiet_mode="

      # Return true if the system is quiet mode.
      #
      # @return [bool]
      def quiet_mode?
        @@quiet_mode
      end
      module_function :quiet_mode?

      # @!group Message Senders

      # Send the debug message.
      #
      # @param msg [String]
      #   debug message
      # @param level [Integer]
      #   indent level
      # @param type [String]
      #   message heading type
      # @return [void]
      def debug_message(msg, level=0, head="debug")
        if debug_mode? and not(quiet_mode?)
          message(:debug, head, :magenta, "  "*level + msg)
        end
      end
      module_function :debug_message

      # Send the debug message to notify that something begins.
      #
      # @param msg [String]
      #   debug message
      # @return [void]
      def debug_message_begin(msg)
        debug_message(msg, 0, ">>>")
      end

      # Send the debug message to notify that something ends.
      #
      # @param msg [String]
      #   debug message
      # @return [void]
      def debug_message_end(msg)
        debug_message(msg, 0, "<<<")
      end

      # Send the user message.
      #
      # @param msg [String]
      #   user message
      # @param level [Integer]
      #   indent level
      # @param type [String]
      #   message heading type
      # @return [void]
      def user_message(msg, level=0, head="info", color=:green)
        if not(quiet_mode?)
          message(:info, head, color, msg, level)
        end
      end

      # Send the user message to notify that something begins.
      #
      # @param msg [String]
      #   user message
      # @return [void]
      def user_message_begin(msg, level=0)
        user_message(msg, level, "-->")
      end

      # Send the debug message to notify that something ends.
      #
      # @param [String] msg
      #   debug message
      # @return [void]
      def user_message_end(msg, level=0)
        user_message(msg, level, "<--")
      end

      # Show the message.
      #
      # @param msg [String]
      #   the message
      #
      # @note
      #   Use this for debugging only.
      #
      # @api private
      def show(msg)
        message(:debug, "show", :red, msg)
      end

      # Print the message with the color.
      #
      # @param type [String]
      #   message type("debug", "info", "show", ">>>", "<<<")
      # @param color [Symbol]
      #   type color(:red, :green, :magenta)
      # @param msg [String]
      #   message content
      #
      # @api private
      def message(type, head, color, msg, level=0)
        write(Tuple[:message].new(type: type, head: head, color: color, contents: msg, level: level))
      rescue NoMethodError
        MESSAGE_QUEUE.push "%s%s %s" % ["  "*level, ("%5s" % head).color(color), msg]
      end
      module_function :message
    end
  end
end
