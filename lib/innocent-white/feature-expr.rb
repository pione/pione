require 'innocent-white/common'

module InnocentWhite
  module FeatureExpr
    # Value represents feature's value.
    class Value
      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
      end

      def ==(other)
        @type == other.type && @identifier == other.identifier
      end

      def ===(feature)
        # match test of this expression
        case @type
        when :requisite
          return true if @identifier == feature
        when :preferred
          return true
        when :exclusive
          return true unless @identifier == feature
        end
        # match test of next expression
        return @next.match(feature) if @next
        # failed
        return false
      end

      alias :match :===
    end

    class Condition
      def initialize(value)
        @value = value
      end
    end

    class Requisite < Condition
      def ===(other)
        other.to_a.any? {|v| @value == v }
      end
    end

    class Exclusive < Condition
      def initialize
        @type = :exclusive
      end
    end

    class FeatureSelective < FeatureExpr

    end

    class FeatureOperator < FeatureExpr
      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class FeatureAnd < FeatureOperator
      def ===(feature)
        
      end
    end

    class FeatureOr < FeatureOperator
    end
  end
end
