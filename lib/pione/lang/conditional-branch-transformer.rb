module Pione
  module Lang
    # ConditionalBranchTransformer is a transformer for all branches.
    module ConditionalBranchTransformer
      include Util::ParsletTransformerModule

      # Transform +if_branch+ into +Lang::IFBranch+.
      rule(:if_branch => subtree(:tree)) {
        # condition and contexts
        expr = tree[:expr]
        true_context = tree[:true_context]
        else_context = tree[:else_context] || Lang::ConditionalBranchContext.new([])

        # make branch
        Lang::IfBranch.new(expr, true_context, else_context).tap do |branch|
          line, col = tree[:declarator].line_and_column
          branch.set_source_position(package_name, filename, line, col)
        end
      }

      # Transform +case_branch+ into +Lang::CaseBranch+.
      rule(:case_branch => subtree(:tree)) {
        # condition and contexts
        condition = tree[:expr]
        when_contexts = tree[:when_contexts].map {|c| [c[:expr], c[:context]]}
        else_context = tree[:else_context] || Lang::ConditionalBranchContext.new([])

        # make branch
        Lang::CaseBranch.new(condition, when_contexts, else_context).tap do |branch|
          line, col = tree[:declarator].line_and_column
          branch.set_source_position(package_name, filename, line, col)
        end
      }
    end
  end
end
