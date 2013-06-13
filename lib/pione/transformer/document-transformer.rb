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
      def initialize(package_name="Main")
        super()
        @current_package_name = package_name
        Thread.current[:current_package_name] = @current_package_name
      end

      def check_model_type(data, type)
        data.pione_model_type == type
      end

      rule(:toplevel_assignment_line => simple(:assignment)) {
        Naming.AssignmentLine(assignment.set_toplevel(true))
      }

      rule(:toplevel_param_line => simple(:naming_param_line)) {
        assignment = naming_param_line.value
        assignment.set_toplevel(true)
        assignment.set_user_param(true)
        Naming.ParamLine(assignment)
      }

      # Transform +:param_block+ as Naming::ParamBlock.
      rule(:param_block => subtree(:tree)) {
        param_type = tree[:param_type]
        assignments = tree[:in_block_assignments]
        _assignments = assignments.map do |assignment|
          assignment.set_toplevel(true)
          assignment.set_user_param(true)
          case param_type
          when "Advanced"
            assignment.set_param_type(:advanced)
          else
            assignment.set_param_type(:basic)
          end
        end
        Naming.ParamBlock(_assignments)
      }

      # Transform +:package+ as Naming::Package.
      rule(:package => subtree(:tree)) {
        @current_package = Naming.Package(tree[:package_name].to_s)
      }
    end
  end
end
