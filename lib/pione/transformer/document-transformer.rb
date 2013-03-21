module Pione
  module Transformer
    # DocumentTransformer is a transformer for syntax tree of document.
    class DocumentTransformer < Parslet::Transform
      include LiteralTransformer
      include FeatureExprTransformer
      include ExprTransformer
      include FlowElementTransformer
      include BlockTransformer
      include RuleDefinitionTransformer

      # @param package_name [String]
      #   package name of the document
      def initialize(package_name="main")
        super()
        @current_package_name = package_name
        Thread.current[:current_package_name] = @current_package_name
      end

      def check_model_type(data, type)
        data.pione_model_type == type
      end

      # Transform +:param_block+ as Naming::ParamBlock.
      rule(:param_block => sequence(:assignment_list)) {
        Naming.ParamBlock(assignment_list)
      }

      # Transform +:package+ as Naming::Package.
      rule(:package => subtree(:tree)) {
        @current_package = Naming.Package(tree[:package_name].to_s)
      }
    end
  end
end
