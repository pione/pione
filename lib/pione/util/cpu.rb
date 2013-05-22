module Pione
  module Util
    # CPU is a name space for CPU related functions.
    module CPU
      # Return CPU core number in this machine. This method tries to find it by
      # using sys-cpu gem, but return 1 if something bad.
      #
      # @return [Integer]
      #    CPU core nunmber
      def core_number
        begin
          [Sys::CPU.processors.size, 1].max
        rescue Object
          1
        end
      end
      module_function :core_number
    end
  end
end
