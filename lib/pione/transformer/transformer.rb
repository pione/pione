module Pione
  module Transformer
    class Transformer < Parslet::Transform
      include Literal
      include FeatureExpr
      include Expr
      include FlowElement
      include Block
      include RuleDefinition

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

      # package
      rule(:package => subtree(:tree)) {
        @current_package = Package.new(tree[:package_name].to_s)
      }
    end
  end
end
