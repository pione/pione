module Pione
  module Tuple
    class PorcessInfoTuple < BasicTuple
      #   name : process name
      #   pid  : process id
      define_format [:process_info, :name, :process_id]
    end
  end
end
