module Pione
  module Transformer
    # FlowElementTransformer is a transformer for syntax tree of flow elements.
    module FlowElementTransformer
      include TransformerModule

      # Extract the content of +flow_elements+.
      rule(:flow_elements => sequence(:elements)) { elements }

      # Transform +call_rule+ into +Model::CallRule+.
      rule(:call_rule => subtree(:rule_expr)) { CallRule.new(rule_expr) }

      # Trasnform +if_block+ into +Model::ConditionalBlock+.
      rule(:if_block => subtree(:tree)) {
        pione_true = Model::BooleanSequence.new([Model::PioneBoolean.true])

        block = Hash.new
        block[pione_true] = Model::FlowBlock.new(*tree[:true_elements])
        block[:else] = Model::FlowBlock.new(*tree[:else_elements]) if tree[:else_elements]

        Model::ConditionalBlock.new(tree[:condition], block)
      }

      # Transform +:case_block+ into +Model::ConditionalBlock+.
      rule(:case_block => subtree(:tree)) {
        block = Hash.new
        tree[:when_blocks].each {|b| block[b.value] = b.elements }
        block[:else] = Model::FlowBlock.new(*tree[:else_elements]) if tree[:else_elements]

        Model::ConditionalBlock.new(tree[:condition], block)
      }

      # Transform +when_block+ into +Model::WhenBlock+.
      rule(:when_block => subtree(:tree)) {
        OpenStruct.new(value: tree[:value], elements: Model::FlowBlock.new(*tree[:elements]))
      }

      # Transform +assignment+ into +Model::Assignment+.
      rule(:assignment => subtree(:tree)) {
        Model::Assignment.new(tree[:symbol], tree[:value])
      }
    end
  end
end
