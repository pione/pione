module Pione
  module Transformer
    # RuleDefinitionTransformer is a transformer for syntax tree of rule definitions.
    module RuleDefinitionTransformer
      include TransformerModule

      # @api private
      def check_model_type(obj, pione_model_type)
        pione_model_type.match(obj.pione_mode_type)
      end
      module_function :check_model_type

      # Transform +:rule_definition+ as Model::Rule.
      rule(:rule_definition => {
          :rule_header => simple(:rule_expr),
          :rule_conditions => sequence(:conditions),
          :block => simple(:block) }) {
        features = Feature.empty if Naming::FeatureLine.values(conditions).empty?
        features = Feature::AndExpr.new(*Naming::FeatureLine.values(conditions)) unless features
        condition = Component::RuleCondition.new(
          inputs: Naming::InputLine.values(conditions),
          outputs: Naming::OutputLine.values(conditions),
          params: Parameters.merge(*Naming::ParamLine.values(conditions)),
          features: features,
          constraints: Constraints.new(Naming::ConstraintLine.values(conditions))
        )
        case block
        when ActionBlock
          Component::ActionRule
        when FlowBlock
          Component::FlowRule
        when EmptyBlock
          Component::EmptyRule
        end.new(rule_expr.package_expr.name, rule_expr.name, condition, block)
      }

      # Transform +:input_line+ as Naming::InputLine.
      rule(:input_line => simple(:data_expr)) {
        TypeDataExpr.check(data_expr)
        Naming.InputLine(data_expr)
      }

      # Transform +output_line+ as Naming::OutputLine.
      rule(:output_line => simple(:data_expr)) {
        TypeDataExpr.check(data_expr)
        Naming.OutputLine(data_expr)
      }

      # Transform +param_line+ as Naming::ParamLine.
      rule(:param_line => subtree(:tree)) {
        param = tree[:param_expr]
        param_type = tree[:param_type]
        unless TypeAssignment.match(param) or param.kind_of?(Variable)
          raise PioneModelTypeError.new(param, TypeAssignment)
        end
        case param_type
        when "advanced"
          param.set_param_type(:advanced)
        else
          param.set_param_type(:basic)
        end
        Naming.ParamLine(param)
      }

      # Transform +:feature_line+ as Naming::FeatureLine.
      rule(:feature_line => simple(:feature)) {
        TypeFeature.check(feature)
        Naming.FeatureLine(feature)
      }

      rule(:constraint_line => simple(:constraint)) {
        Naming.ConstraintLine(constraint)
      }

      rule(:annotation_line => simple(:expr)) {
        Naming.AnnotationLine(expr)
      }
    end
  end
end
