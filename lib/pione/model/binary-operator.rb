module Pione::Model

  # BinaryOperator represents applications between Pione model objects.
  # @example
  #   1 + 1
  # @example
  #   true == false
  # @example
  #   $X * $Y
  class BinaryOperator < PioneModelObject
    attr_reader :symbol
    attr_reader :left
    attr_reader :right

    # Create a binary operator.
    # @param [String] symbol
    #   operator's symbol
    # @param [PioneModelObject] left
    #   left operand
    # @param [PioneModelObject] right
    #   right operand
    def initialize(symbol, left, right)
      @symbol = symbol
      @left = left
      @right = right
      super()
    end

    # Returns false because Message has complex form.
    # @return [Boolean]
    #   false
    def atomic?
      false
    end

    # Returns true if the left or right expression includes variable.
    # @return [Boolean]
    #    true if the left or right expression includes variable
    def include_variable?
      @left.include_variable? or @right.include_variable?
    end

    # @api private
    def pione_model_type
      @left.pione_model_type.method_interface[@symbol].output
    end

    # Evaluates the application expression and returns application result.
    # @param [VariableTable] vtable
    #   variable table for the evaluation
    # @return [PioneModelObject]
    #   evaluation result object
    def eval(vtable)
      left = @left.eval(vtable)
      right = @right.eval(vtable)
      left.call_pione_method(@symbol, right)
    end

    # @api private
    def textize
      "%s%s%s" % [@left.textize, @symbol.textize, @right.textize]
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
