module Pione
  module Log
    # Debug is a log utility module for showing debug messages. Messages are
    # shown when according debug flags (system, rule_engine, notification,
    # communication, ignored_exception) are available.
    module Debug
      # Show a debug message about PIONE system activity. This message is
      # visible when `Global.debug_system` is true.
      def self.system(msg_or_exc=nil, pos=caller(1).first, &b)
        if Global.debug_system
          print(:system, msg_or_exc, pos, &b)
        end
      end

      # Show a debug message about rule engine activity. This message is visible
      # when `Global.debug_rule_engine` is true in client side.
      def self.rule_engine(msg_or_exc=nil, pos=caller(1).first, &b)
        if Global.debug_rule_engine
          print(:rule_engine, msg_or_exc, pos, &b)
        end
      end

      # Show a debug message about notification. This message is visible when
      # `Global.debug_notification` is true.
      def self.notification(msg_or_exc=nil, pos=caller(1).first, &b)
        if Global.debug_notification
          print(:notification, msg_or_exc, pos, &b)
        end
      end

      # Show a debug message abount object communication. This message is
      # visible when +Global.debug_communication+ is true.
      def self.communication(msg_or_exc=nil, pos=caller(1).first, &b)
        if Global.debug_communication
          print(:communication, msg_or_exc, pos, &b)
        end
      end

      # Show a ignored exception. This message is visible when
      # +Global.debug_ignored_exception+ is true.
      def self.ignored_exception(msg_or_exc=nil, pos=caller(1).first, &b)
        if Global.debug_ignored_exception
          print(:ignored_exception, msg_or_exc, pos, &b)
        end
      end

      private

      # Print a debug message or an exception.
      def self.print(type, msg_or_exc, pos, &b)
        _msg_or_exc = block_given? ? b.call : msg_or_exc
        if msg_or_exc.is_a?(Exception)
          print_exception(type, _msg_or_exc, pos)
        else
          print_debug_message(type, _msg_or_exc, pos)
        end
      end

      # Print a debug message.
      def self.print_debug_message(type, msg, pos)
        SystemLog.debug("%s: %s" % [prefix(type), msg], pos)
      end

      # Print an exception.
      def self.print_exception(type, e, pos)
        backtrace = e.backtrace.map{|line|  "    %s" % line}.join("\n")
        SystemLog.debug("%s: %s - %s\n%s" % [prefix(type), e.class, e.message, backtrace], pos)
      end

      def self.prefix(type)
        type.to_s.underline
      end
    end
  end
end
