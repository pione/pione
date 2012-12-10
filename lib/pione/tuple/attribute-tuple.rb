module Pione
  module Tuple
    class AttributeTuple < BasicTuple
      define_format [:attribute, [:key, String], :value]
    end
  end
end
