module Pione
  module Tuple
    # FinishedTuple represents task finished notifier.
    class FinishedTuple < BasicTuple
      define_format [:finished,
        # task domain
        [:domain, String],
        # status of the task processing
        [:status, Symbol],
        # outputs
        [:outputs, Array],
        # rule handler digest
        [:digest, String]
      ]
    end
  end
end
