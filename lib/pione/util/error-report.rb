module Pione
  module Util
    module ErrorReport
      # Prints the pretty exception.
      def print(e)
        $stderr.puts "%s: %s" % [e.class, e.message]
        caller.each {|line| puts "    %s" % line}
      end
      module_function :print
    end
  end
end
