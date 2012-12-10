module Pione
  module Tuple
    # WorkingTuple represents current working task informations.
    class WorkingTuple < BasicTuple
      define_format [:working,
        # caller domain
        [:domain, String],
        # rule handler digest
        [:digest, String]
      ]
    end
  end
end
