module Pione
  module Tuple
    # LiftTuple represents data movement information from old location to new
    # location.
    class LiftTuple < BasicTuple
      define_format [:lift,
        # old location
        [:old_location, Location::BasicLocation],
        # new location
        [:new_location, Location::BasicLocation]
      ]
    end
  end
end
