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
        Rule::FlowElement::CallRule.new(rule_expr)
      }

      rule(:if_block =>
           { :if_true_elements => sequence(:if_true),
             :if_false_elements => sequence(:if_false),
             :condition => simple(:condition)
           }) do
        block = {true => if_true, :else => if_false}
        Rule::FlowElement::Condition.new(condition, block)
      end

      rule(:case_block =>
           { :when_block => subtree(:when_block) } ) {
        variable = case_block[:variable].to_s
        block = {}
        case_block[:when_block].each do |t|
          block[t[:when].to_s] = t[:elements]
        end
        block[:else] = case_block[:else_elements]
        Rule::FlowElement::Condition.new(variable, block)
      }
    end
  end
end
