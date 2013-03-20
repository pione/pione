module Pione
  module Transformer
    module RuleDefinitionTransformer
      include TransformerModule

      def check_model_type(obj, pione_model_type)
        pione_model_type.match(obj.pione_mode_type)
      end
      module_function :check_model_type

      # rule_definition
      rule(:rule_definition => {
          :rule_header => simple(:rule_expr),
          :rule_conditions => sequence(:conditions),
          :block => simple(:block) }) {
        inputs = Naming::InputLine.values(conditions)
        outputs = Naming::OutputLine.values(conditions)
        params = Parameters.merge(*Naming::ParamLine.values(conditions))
        features = Feature::AndExpr.new(*Naming::FeatureLine.values(conditions))
        condition = RuleCondition.new(inputs, outputs, params, features)
        case block
        when ActionBlock
          ActionRule
        when FlowBlock
          FlowRule
        end.new(rule_expr, condition, block)
      }

      # input_line
      rule(:input_line => simple(:data_expr)) {
        TypeDataExpr.check(data_expr)
        Naming.InputLine(data_expr)
      }

      # output_line
      rule(:output_line => simple(:data_expr)) {
        TypeDataExpr.check(data_expr)
        Naming.OutputLine(data_expr)
      }

      # param_line
      rule(:param_line => simple(:param)) {
        unless TypeAssignment.match(param) or TypeParameters.match(param)
          raise PioneModelTypeError.new(param, TypeAssignment)
        end
        Naming.ParamLine(param)
      }

      # feature_line
      rule(:feature_line => simple(:feature)) {
        TypeFeature.check(feature)
        Naming.FeatureLine(feature)
      }
    end
  end
end
