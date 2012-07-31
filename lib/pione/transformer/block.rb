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
        { :key => simple(:keyword_Action),
          :content => simple(:content) }
      ) {
        line_and_column = keyword_Action.line_and_column
        ActionBlock.new(content) do
          set_line_and_column(line_and_column)
        end
      }
    end
  end
end
