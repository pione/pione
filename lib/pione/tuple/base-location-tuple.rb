module Pione
  module Tuple
    # BaseLocationTuple represents base location for processing results.
    class BaseLocationTuple < BasicTuple
      #  base location of all resources on the server
      define_format [:base_location, :location]
    end
  end
end
