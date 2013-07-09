module Pione
  module Transformer
    # BlockTransformer is a transformer for syntax tree of blocks.
    module BlockTransformer
      include TransformerModule

      # Transform +:flow_block+ as Model::FlowBlock.
      rule(:flow_block => sequence(:elements)) {
        FlowBlock.new(*elements)
      }

      # Transform +:action_block+ as Model::ActionBlock.
      rule(:action_block =>
        { :key => simple(:keyword_Action),
          :content => simple(:content) }
      ) {
        val = Util::Indentation.cut(content.str)
        ActionBlock.new(val).tap do |x|
          x.set_line_and_column(keyword_Action.line_and_column)
        end
      }

      rule(:empty_block => simple(:any)) {
        EmptyBlock.instance
      }
    end
  end
end
