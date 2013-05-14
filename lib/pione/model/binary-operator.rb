module Pione
  module Model
    # BinaryOperator represents applications between Pione model objects.
    #
    # @example
    #   1 + 1
    # @example
    #   true == false
    # @example
    #   $X * $Y
    class BinaryOperator < BasicModel
      attr_reader :symbol
      attr_reader :left
      attr_reader :right

      # Create a binary operator.
      #
      # @param symbol [String]
      #   operator's symbol
      # @param left [BasicModel]
      #   left operand
      # @param right [BasicModel]
      #   right operand
      def initialize(symbol, left, right)
        @symbol = symbol
        @left = left
        @right = right
        super()
      end

      # Return false because Message has complex form.
      #
      # @return [Boolean]
      #   false
      def atomic?
        false
      end

      # Return true if the left or right expression includes variable.
      #
      # @return [Boolean]
      #    true if the left or right expression includes variable
      def include_variable?
        @left.include_variable? or @right.include_variable?
      end

      # @api private
      def pione_model_type
        if pione_method = @left.pione_model_type.find_method(@symbol, @left, @right)
          return pione_method.get_output_type(@left)
        else
          raise MethodNotFound.new(@name.to_s, @left, @right)
        end
      end

      # Evaluate the application expression and returns application result.
      #
      # @param vtable [VariableTable]
      #   variable table for the evaluation
      # @return [BasicModel]
      #   evaluation result object
      def eval(vtable)
        left = @left.eval(vtable)
        right = @right.eval(vtable)
        left.call_pione_method(@symbol, right)
      end

      # @api private
      def textize
        "%s%s%s" % [@left.textize, @symbol.to_s, @right.textize]
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless @symbol == other.symbol
        return false unless @left == other.left
        return false unless @right == other.right
        return true
      end

      alias :eql? :"=="

      # @api private
      def hash
        @symbol.hash + @left.hash + @right.hash
      end
    end
  end
end
