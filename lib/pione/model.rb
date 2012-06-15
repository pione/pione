module Pione::Model
  class PioneModelObject < PioneObject
    # Returns self.
    def eval(vtable)
      return self
    end
  end

  require 'pione/model/variable'
  require 'pione/model/variable-table'
  require 'pione/model/data-expr'
  require 'pione/model/rule-expr'

  module Expr
    class BinaryOperator < PioneObject
      attr_reader :symbol
      attr_reader :left
      attr_reader :right

      def self.match(symbol)
        symbol == @symbol
      end

      def self.make(symbol, left, right)
        get_class(symbol).new(left, right)
      end

      def self.get_class(symbol)
        case symbol
        when "=="
          Equals
        when ">"
          GreaterThan
        end
      end

      def initialize(left, right)
        @left = left
        @right = right
      end

      def eval(vtable=VariableTable.new)
        @left.eval(vtable)
        @right.eval(vtable)
        calc(@left, @right)
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless @left == other.left
        return false unless @right == other.right
        return true
      end
    end

    class Equals < BinaryOperator
      @symbol = "=="

      def calc(a, b)
        a == b
      end
    end

    class GreaterThan < BinaryOperator
      @symbol = ">"

      def calc(a, b)
        a > b
      end
    end
  end
end
