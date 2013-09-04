module Pione
  module Tuple
    # EnvTuple is a tuple for sharing language environment.
    class EnvTuple < BasicTuple
      define_format [:env, :obj]
    end
  end
end
