module Pione
  module Transformer
    # DeclarationTransformer is a transformer for all declarations.
    module DeclarationTransformer
      include TransformerModule

      #
      # sentences
      #

      # Transform +variable_binding_sentence+ into +Lang::VariableBindingDeclaration+.
      rule(:variable_binding_sentence => subtree(:tree)) {
        Lang::VariableBindingDeclaration.new(tree[:expr1], tree[:expr2]).tap do |declaration|
          line, col = (tree[:declarator] || tree[:expr1]).line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +package_binding_sentence+ into +Lang::PackageBindingDeclaration+.
      rule(:package_binding_sentence => subtree(:tree)) {
        Lang::PackageBindingDeclaration.new(tree[:expr1], tree[:expr2]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +param_sentence+ into +Lang::ParamDeclaration+.
      rule(:param_sentence => subtree(:tree)) {
        type = (tree[:type] || "basic").to_sym

        Lang::ParamDeclaration.new(type, tree[:expr1], tree[:expr2]).tap do |declaration|
          line, col = (tree[:type] || tree[:declarator]).line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +rule_binding_sentence+ into +Lang::RuleBindingDeclaration+.
      rule(:rule_binding_sentence => subtree(:tree)) {
        Lang::RuleBindingDeclaration.new(tree[:expr1], tree[:expr2]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +constituent_rule_sentence+ into +Lang::ConstituentRuleDeclaration+.
      rule(:constituent_rule_sentence => subtree(:tree)) {
        Lang::ConstituentRuleDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +:input_sentence+ into +Lang::InputDeclaration+.
      rule(:input_sentence => subtree(:tree)) {
        Lang::InputDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +output_sentence+ into +Model::OutputDeclaration+.
      rule(:output_sentence => subtree(:tree)) {
        Lang::OutputDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +feature_sentence+ into +Lang::FeatureDeclaration+.
      rule(:feature_sentence => subtree(:tree)) {
        Lang::FeatureDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +constraint_sentence+ into +Lang::ConstraintDeclaration+.
      rule(:constraint_sentence => subtree(:tree)) {
        Lang::ConstraintDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +annotation_sentence+ into +Lang::AnnotationDeclaration+.
      rule(:annotation_sentence => subtree(:tree)) {
        Lang::AnnotationDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +expr_sentence+ into +Lang::ExprDeclaration+.
      rule(:expr_sentence => subtree(:tree)) {
        Lang::ExprDeclaration.new(tree[:expr]).tap do |declaration|
          line, col = (tree[:declarator] || tree[:expr]).line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      #
      # blocks
      #

      # Transform +param_block+ into +Lang::ParamBlock+.
      rule(:param_block => subtree(:tree)) {
        type = (tree[:type] || "basic").to_s.downcase.to_sym
        context = tree[:context].set(type: type)

        Lang::ParamBlockDeclaration.new(type, context).tap do |declaration|
          line, col = (tree[:type] || tree[:declarator]).line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +flow_rule_block+ into +Lang::FlowRuleDeclaration+.
      rule(:flow_rule_block => subtree(:tree)) {
        expr = tree[:expr]
        condition_context = tree[:context1]
        flow_context = tree[:context2]

        Lang::FlowRuleDeclaration.new(expr, condition_context, flow_context).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +action_rule_block+ into +Lang::ActionRuleDeclaration+.
      rule(:action_rule_block => subtree(:tree)) {
        expr = tree[:expr]
        condition_context = tree[:context1]
        action_context = tree[:context2]

        Lang::ActionRuleDeclaration.new(expr, condition_context, action_context).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +empty_rule_block+ into +Lang::EmptyRuleDeclaration+.
      rule(:empty_rule_block => subtree(:tree)) {
        expr = tree[:expr]
        condition_context = tree[:context]

        Lang::EmptyRuleDeclaration.new(expr, condition_context).tap do |declaration|
          line, col = tree[:declarator].line_and_column
          declaration.set_source_position(package_name, filename, line, col)
        end
      }
    end
  end
end

