module Pione
  module Tuple
    class ExceptionTuple < BasicTuple
      # exception notifier from agents
      #   uuid  : uuid of the agent who happened the exception
      #   value : exception object
      define_format [:exception, :uuid, :agent_type, :value]
    end
  end
end

