module Pione
  module Util
    # Message is a set of utility methods for sending messages to user.
    module Message
      # @api private
      MessageQueue = Queue.new

      # message queue thread
      Thread.new {
        while msg = MessageQueue.pop
          puts msg
        end
      }

      # @!group Message Mode

      # @api private
      @@debug_mode = false

      # @api private
      @@quiet_mode = false

      # Evaluates the block in debug mode.
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

      # Sets debug mode.
      # @param [bool] mode
      #   flag of debug mode
      # @return [void]
      def debug_mode=(mode)
        @@debug_mode = mode
      end
      module_function :"debug_mode="

      # Return true if the system is debug mode.
      # @return [bool]
      def debug_mode?
        @@debug_mode
      end
      module_function :debug_mode?

      # Evaluates the block in quiet mode.
      # @yield []
      #   target block
      # @return [void]
      def quiet_mode
        orig = @@quiet_mode
        @@quiet_mode = true
        yield
        @@quiet_mode = orig
      end
      module_function :debug_mode

      # Sets quiet mode.
      # @param [bool] mode
      #   flag of quiet mode
      # @return [void]
      def quiet_mode=(mode)
        @@quiet_mode = mode
      end
      module_function :"quiet_mode="

      # Return true if the system is quiet mode.
      # @return [bool]
      def quiet_mode?
        @@quiet_mode
      end
      module_function :quiet_mode?

      # @!group Message Senders

      # Sends the debug message.
      # @param [String] msg
      #   debug message
      # @param [Integer] level
      #   indent level
      # @param [String] type
      #   message heading type
      # @return [void]
      def debug_message(msg, level=0, type="debug")
        if debug_mode? and not(quiet_mode?)
          message(type, :magenta, "  "*level + msg)
        end
      end

      # Sends the debug message to notify that something begins.
      # @param [String] msg
      #   debug message
      # @return [void]
      def debug_message_begin(msg)
        debug_message(msg, 0, ">>>")
      end

      # Sends the debug message to notify that something ends.
      # @param [String] msg
      #   debug message
      # @return [void]
      def debug_message_end(msg)
        debug_message(msg, 0, "<<<")
      end

      # Sends the user message.
      # @param [String] msg
      #   user message
      # @param [Integer] level
      #   indent level
      # @param [String] type
      #   message heading type
      # @return [void]
      def user_message(msg, level=0, type="info")
        if not(quiet_mode?)
          message(type, :green, "  "*level + msg)
        end
      end

      # Sends the user message to notify that something begins.
      # @param [String] msg
      #   user message
      # @return [void]
      def user_message_begin(msg)
        user_message(msg, 0, ">>>")
      end

      # Sends the debug message to notify that something ends.
      # @param [String] msg
      #   debug message
      # @return [void]
      def user_message_end(msg)
        user_message(msg, 0, "<<<")
      end

      # use this internal debug only
      # @api private
      def show(msg)
        message("show", :red, msg)
      end

      # @api private
      def message(type, color, msg)
        MessageQueue.push "%s %s" % [Terminal.color(color, "%5s" % type), msg]
      end
    end
  end
end
