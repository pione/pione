module Pione
  module Tuple
    # AgentTuple represents agents information in a tuple space server.
    class AgentTuple < BasicTuple
      #   uuid       : uuid of the agent
      #   agent_type : agent type
      define_format [:agent, :uuid, :agent_type]
    end
  end
end
