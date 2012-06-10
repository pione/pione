require 'pione/common'

module Pione
  module Feature
    class Unification
      def unify_and(expr)
        return false unless expr.kind_of?(And)
        if expr.left == expr.right
          expr.left
        else
          if expr.left.kind_of?(And)
      end

      def unify_and_by_empty_feature(a, b)
        return expr.left if a.empty?
        return expr.right if b.empty?
        return false
      end

      def unify_or(a, b)
        a == b ? :left : false
      end

      def or_unification_by_empty_feature(a, b)
        
      end
    end
  end
end
