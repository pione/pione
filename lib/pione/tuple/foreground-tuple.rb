module Pione
  module Tuple
    class ForegroundTuple < BasicTuple
      define_format [:foreground, :domain, :digest]
    end
  end
end
