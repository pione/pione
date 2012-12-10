module Pione
  module Tuple
    # bye message from agent
    class ByeTuple < BasicTuple
      # uuid : uuid of the agent
      define_format [:bye, :uuid, :agent_type]
    end
  end
end
