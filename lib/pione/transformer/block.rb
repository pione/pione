module Pione
  class Transformer
    module Block
      include TransformerModule

      # flow_block:
      rule(:flow_block => sequence(:elements)) {
        return Rule::FlowBlock.new(elements)
      }

      # action_block:
      rule(:action_block => simple(:body)) {
        return Rule::ActionBlock.new(body)
      }
    end
  end
end
