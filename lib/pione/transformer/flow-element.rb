module Pione
  class Transformer
    module FlowElement
      include TransformerModule

      # flow_elements returns just elements sequence
      rule(:flow_elements => sequence(:elements)) {
        elements
      }

      # call_rule
      rule(:call_rule => subtree(:rule_expr)) {
        Model::CallRule.new(rule_expr)
      }

      # if_block
      rule(:if_block =>
           { :condition => simple(:condition),
             :if_true_elements => sequence(:if_true),
             :if_else_block => simple(:if_false)
           }) {
        block = { true => Model::Block.new(*if_true) }
        block[:else] = if_false if if_false
        Model::ConditionalBlock.new(condition, block)
      }

      # else_block
      rule(:else_block =>
           { :elements => sequence(:elements) }) {
        Model::Block.new(*elements)
      }

      # case_block
      rule(:case_block =>
           { :condition => simple(:condition),
             :when_blocks => sequence(:when_blocks),
             :case_else_block => simple(:else_block) }) {
        block = {}
        when_blocks.each do |when_block|
          block[when_block.value] = when_block.body
        end
        block[:else] = else_block if else_block
        ConditionalBlock.new(condition, block)
      }
    end

    WhenBlock = Struct.new(:value, :body)

    # when_block
    rule(:when_block =>
         { :value => simple(:value),
           :elements => sequence(:elements) }) {
      WhenBlock.new(value, Model::Block.new(*elements))
    }
  end
end
