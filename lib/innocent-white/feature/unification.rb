require 'innocent-white/common'

module InnocentWhite
  module Feature
    class Unification
      def and_unification(a, b)
        a == b ? :left : false
      end

      def and_unification_by_empty_feature(a, b)
        return :left if a.empty?
        return :right if b.empty?
        return false
      end

    end
  end
end
