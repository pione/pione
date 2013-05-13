module Pione
  module Transformer
    # FlowElementTransformer is a transformer for syntax tree of flow elements.
    module FlowElementTransformer
      include TransformerModule

      # Extract the content of +:flow_elements+.
      rule(:flow_elements => sequence(:elements)) {
        elements
      }

      # Transform +:call_rule: as Model::CallRule.
      rule(:call_rule => subtree(:rule_expr)) {
        CallRule.new(rule_expr)
      }

      # Trasnform +:if_block+ as Model::ConditionalBlock.
      rule(:if_block =>
           { :condition => simple(:condition),
             :if_true_elements => sequence(:if_true),
             :if_else_block => simple(:if_false)
           }) {
        block = {
          Model::BooleanSequence.new([Model::PioneBoolean.true]) =>
          Model::FlowBlock.new(*if_true)
        }
        block[:else] = if_false if if_false
        Model::ConditionalBlock.new(condition, block)
      }

      # Transform +:else_block+ as Model::FlowBlock.
      rule(:else_block => {:elements => sequence(:elements)}) {
        Model::FlowBlock.new(*elements)
      }

      # Transform +:case_block+ as Model::ConditionalBlock.
      rule(:case_block =>
        { :condition => simple(:condition),
          :when_blocks => sequence(:when_blocks),
          :case_else_block => simple(:else_block) }) {
        block = {}
        when_blocks.each do |when_block|
          block[when_block.value] = when_block.body
        end
        block[:else] = else_block if else_block
        Model::ConditionalBlock.new(condition, block)
      }

      # Transform +:when_block+ as Model::WhenBlock.
      rule(:when_block =>
        { :value => simple(:value),
          :elements => sequence(:elements) }
      ) {
        OpenStruct.new(value: value, body: Model::FlowBlock.new(*elements))
      }

    # Transform +:assignment+ as Model::Assignment.
      rule(:assignment =>
        { :symbol => simple(:symbol),
          :value => simple(:value) }
      ) {
        Model::Assignment.new(symbol, value)
      }
    end
  end
end
