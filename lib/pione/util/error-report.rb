module Pione
  module Util
    module ErrorReport
      # Prints the pretty exception.
      def print(e)
        $stderr.puts "%s: %s" % [e.class, e.message]
        e.backtrace.each {|line| $stderr.puts "    %s" % line}
      end
      module_function :print

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
    end
  end
end
