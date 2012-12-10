module Pione
  module Tuple
    # BaseURITuple represents base location information of resource.
    class BaseURITuple < BasicTuple
      #  base uri of all resources on the server
      define_format [:base_uri, :uri]
    end
  end
end
