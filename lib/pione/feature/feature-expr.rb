require 'pione/common'

module Pione
  module Feature

    # Base is a super class for all feature expressions.
    class Expr
      def match(other)
        raise NotImplementedError
      end

      alias :=== :match
    end

    # Symbol represents feature symbols.
    class Symbol < Expr
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

    # Operator
    class Operator < Expr
      def initialize(value)
        @value = value
      end
    end

    # UnaryOperator is a class for provider opeators and request operator
    class UnaryOperator < Operator; end

    # ProviderOperator is a class for provider operators.
    class ProviderOperator < UnaryOperator; end

    # PossibleOperator is a class for possible feature expressions. Possible
    # feature are written like as "^X", these represent feature's possible
    # ability.
    class PossibleExpr < ProviderOperator; end

    # RestrictiveOperator is a class for restrictive feature expression.
    class RestrictiveExpr < ProviderOperator; end

    # RequestOperator is a class for task's feature expression operators.
    class RequestOperator < UnaryOperator; end

    # Requisite Operator is a class for requisite feature expressions. Requisite
    # Feature are written like as "+X", these represent feature's requiste
    # ability.
    class RequisiteOperator < RequestOperator
      def ===(other)
        other.to_a.any? {|v| @value == v }
      end
    end

    # 
    class BlockingOperator < RequestOperator; end

    class PreferredOperator < RequestOperator; end

    class Connective < Base
      attr_reader :left
      attr_reader :right

      def initialize(left, right)
        @left = left
        @right = right
      end
    end

    class AndExpr < Connective; end

    class OrExpr < Connective; end

    class Sentence < Expr; end
  end
end
