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

      BLOCK_TO_RULE_TYPE = {
        Model::ActionBlock => Component::ActionRule,
        Model::FlowBlock   => Component::FlowRule,
        Model::EmptyBlock  => Component::EmptyRule
      }

      # Transform +rule_definition+ into +Component::Rule+.
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
        BLOCK_TO_RULE_TYPE[block.class].new(rule_expr.package_expr.name, rule_expr.name, condition, block)
      }

      # Transform +:input_line+ into +Naming::InputLine+.
      rule(:input_line => simple(:data_expr)) {
        TypeDataExpr.check(data_expr)
        Naming.InputLine(data_expr)
      }

      # Transform +output_line+ into +Naming::OutputLine+.
      rule(:output_line => simple(:data_expr)) {
        TypeDataExpr.check(data_expr)
        Naming.OutputLine(data_expr)
      }

      # Transform +param_line+ into +Naming::ParamLine+.
      rule(:param_line => subtree(:tree)) {
        expr = tree[:param_expr]
        type = tree[:type]
        unless TypeAssignment.match(expr) or expr.kind_of?(Variable)
          raise PioneModelTypeError.new(expr, TypeAssignment)
        end
        case type
        when "advanced"
          expr.set_param_type(:advanced)
        else
          expr.set_param_type(:basic)
        end
        Naming.ParamLine(expr)
      }

      # Transform +feature_line+ into +Naming::FeatureLine+.
      rule(:feature_line => simple(:feature)) {
        TypeFeature.check(feature)
        Naming.FeatureLine(feature)
      }

      # Transform +constraint_line+ into +Naming::ConstraintLine+.
      rule(:constraint_line => simple(:constraint)) { Naming.ConstraintLine(constraint) }

      # Transform +annotation_line+ into +Naming::AnnotationLine+.
      rule(:annotation_line => simple(:expr)) { Naming.AnnotationLine(expr) }
    end
  end
end
