module Pione
  class Transformer
    module Block
      include TransformerModule

      # flow_block:
      rule(:flow_block => sequence(:elements)) {
        FlowBlock.new(*elements)
      }

      # action_block:
      rule(:action_block =>
        { :content => simple(:content) }
      ) {
        ActionBlock.new(content)
      }
    end
  end
end
