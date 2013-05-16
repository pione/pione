module Pione
  module Tuple
    # DataNullTuple is a tuple for the situation that output data is null.
    class DataNullTuple < BasicTuple
      define_format [:data_null,
        # target domain
        [:domain, String],
        # output condition position
        [:position, Integer]
      ]
    end
  end
end

