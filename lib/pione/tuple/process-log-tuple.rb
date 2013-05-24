module Pione
  module Tuple
    # ProcessLogTuple represents process event messages.
    class ProcessLogTuple < BasicTuple
      define_format [:process_log, [:message, Log::ProcessRecord]]

      def timestamp=(time)
        @timestamp = time
        message.timestamp = time
      end
    end
  end
end
