module Pione
  module Tuple
    class TouchTuple < BasicTuple
      define_format [:touch,
        # target domain
        [:domain, String],
        # name
        [:name, String],
        # touched time
        [:time, Time]
      ]
    end
  end
end
