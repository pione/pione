module Pione
  module Tuple
    # ShiftTuple represents resource shift information.
    class ShiftTuple < BasicTuple
      define_format [:shift,
        # old uri
        [:old_uri, String],
        # new uri
        [:new_uri, String]
      ]
    end
  end
end
