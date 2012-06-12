module Pione
  module Transformer
    module FlowElement
      include TransformerModule

      rule(:rule_call => subtree(:rule_expr)) {
        Rule::FlowElement::CallRule.new(rule_expr)
      }

      rule(:if_block => subtree(:block)) {
        variable = block[:variable].to_s
        true_elements = block[:true_elements]
        else_elements = block[:else_elements] || []
        block = {true => true_elements, :else => else_elements}
        Rule::FlowElement::Condition.new(variable, block)
      }

      rule(:case_block => subtree(:case_block)) {
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
