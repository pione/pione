module Pione
  module Tuple
    # CommandTuple represents signals for PIONE system.
    class CommandTuple < BasicTuple
      #   type : command string, currently "terminate" only
      define_format [:command, :name, :args]
    end
  end
end
