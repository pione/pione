module Pione
  module Tuple
    # LogTuple represents log messages.
    class LogTuple < BasicTuple
      #   obj : Log's instance
      define_format [:log, :message]

      def timestamp=(time)
        @timestamp = time
        message.timestamp = time
      end
    end
  end
end
