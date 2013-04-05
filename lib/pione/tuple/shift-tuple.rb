module Pione
  module Tuple
    # ShiftTuple represents location shift information.
    class ShiftTuple < BasicTuple
      define_format [:shift,
        # old location
        [:old_location, Location::BasicLocation],
        # new location
        [:new_location, Location::BasicLocation]
      ]
    end
  end
end
