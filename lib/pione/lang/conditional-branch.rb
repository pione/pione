module Pione
  module Lang
    # ConditionalBranch is a base class for all conditional branches. PIONE's
    # branch works as the function that controls availability of declarations.
    class ConditionalBranch < StructX
      include Util::Positionable
    end

    # IfBranch is a class for +if+ branches.
    class IfBranch < ConditionalBranch
      member :expr         # condition
      member :true_context # true-context
      member :else_context # else-context

      # Validate inner contexts based on the list of acceptances.
      def validate(acceptances)
        true_context.validate(acceptances)
        else_context.validate(acceptances)
      end

      # Return suitable context in the environment.
      def eval(env)
        # evaluate the condition
        res = expr.eval!(env)

        # check type of the result
        unless res.is_a?(Model::BooleanSequence)
          raise StructuralError.new(Model::BooleanSequence, expr.pos)
        end

        # return true_context when it is true
        return true_context if res.value

        # or return else_context when the context exists
        return else_context if else_context

        # otherwise return empty context
        return ConditionalBranchContext.new
      end

      def eval!(env)
        eval(env).eval!(env)
      end
    end

    # CaseBranch is a class for +case+ branches.
    class CaseBranch < ConditionalBranch
      member :expr          # conditional value
      member :when_contexts # when contexts(list of pair of expr and context)
      member :else_context  # else context

      # Validate inner contexts based on the list of acceptances.
      def validate(acceptances)
        when_contexts.each {|_expr, _context| _context.validate(acceptances)}
        else_context.validate(acceptances)
      end

      # Return suitable context in the environment.
      def eval(env)
        # evaluate the condition
        val = expr.eval!(env)

        # return matched branch's context
        matched = when_contexts.find do |_expr, _context|
          val.call_pione_method(env, "==*", [_expr]).value
        end

        # return matched context, else-context, or empty context
        return matched || else_context || ConditionalBranchContext.new
      end
    end
  end
end
