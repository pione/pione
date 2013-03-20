module Pione
  module Transformer
    class DocumentTransformer < Parslet::Transform
      include LiteralTransformer
      include FeatureExprTransformer
      include ExprTransformer
      include FlowElementTransformer
      include BlockTransformer
      include RuleDefinitionTransformer

      def initialize(package_name="main")
        super()
        @current_package_name = package_name
        Thread.current[:current_package_name] = @current_package_name
      end

      def apply(*args)
        res = super
        return res
      end

      def check_model_type(data, type)
        data.pione_model_type == type
      end

      #
      # statement
      #

      rule(:param_block => sequence(:assignment_list)) {
        Naming.ParamBlock(assignment_list)
      }

      # package
      rule(:package => subtree(:tree)) {
        @current_package = Naming.Package(tree[:package_name].to_s)
      }
    end
  end
end
