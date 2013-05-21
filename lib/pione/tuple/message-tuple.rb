module Pione
  module Tuple
    class MessageTuple < BasicTuple
      define_format [:message, :type, :head, :color, :level, :contents]
    end
  end
end
