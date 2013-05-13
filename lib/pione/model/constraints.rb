module Pione
  module Model
    class Constraints
      class << self
        # Return the empty constraints.
        #
        # @return [Constraints]
        #   empty constraints
        def empty
          new([])
        end
      end

      # @param exprs [Array<BasicModel>]
      #   constraint expressions
      def initialize(exprs)
        @exprs = exprs
      end

      # Return true if constraints satisfied.
      #
      # @param vtable [VariableTable]
      #   variable table
      # @return [Boolean]
      #   true if constraints satisfied
      def satisfy?(vtable)
        @exprs.all? do |expr|
          res = expr.eval(vtable)
          res.kind_of?(BooleanSequence) and res.value
        end
      end
    end
  end
end
