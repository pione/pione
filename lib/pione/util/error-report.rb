module Pione
  module Util
    module ErrorReport
      # Prints the pretty exception.
      def print(e)
        $stderr.puts "%s: %s" % [e.class, e.message]
        e.backtrace.each {|line| $stderr.puts "    %s" % line}
      end
      module_function :print

      def abort(msg, receiver, exception, file, line)
        error(msg, receiver, exception, file, line)
        ::Process.abort
      end
      module_function :abort

      def error(msg, receiver, exception, file, line)
        $stderr.puts "PIONE error [%s:%i] %s (%s)" % [file, line, msg, receiver]
        print(exception)
      end
      module_function :error

      def warn(msg, receiver, exception, file, line)
        if Pione.debug_mode?
          $stderr.puts "PIONE warning [%s:%i] %s (%s)" % [file, line, msg, receiver]
          print(exception)
        end
      end
      module_function :warn

      def debug(msg, receiver, file, line)
        if Pione.debug_mode?
          $stderr.puts "PIONE debug [%s:%i] %s (%s)" % [file, line, msg, receiver]
        end
      end
      module_function :debug

      def presence_notifier(msg, receiver, file, line)
        if Global.show_presence_notifier
          $stderr.puts "PIONE presence notifier [%s:%i] %s (%s)" % [file, line, msg, receiver]
        end
      end
      module_function :presence_notifier
    end
  end
end
