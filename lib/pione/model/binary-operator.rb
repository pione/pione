module Pione::Model

  # BinaryOperator represents applications between Pione model objects.
  # For exmaple,
  #   1 + 1
  #   true == false
  #   $X * $Y
  class BinaryOperator < PioneModelObject
    attr_reader :symbol
    attr_reader :left
    attr_reader :right

    # @param [String] symbol operator's symbol
    # @param [PioneModelObject] left left operand
    # @param [PioneModelObject] right right operand
    def initialize(symbol, left, right)
      @symbol = symbol
      @left = left
      @right = right
    end

    # Returns false because Message is a complex form.
    def atomic?
      false
    end

    def include_variable?
      @left.include_variable? or @right.include_variable?
    end

    def pione_model_type
      @left.pione_model_type.method_interface[@symbol].output
    end

    # Evaluates the application expression and returns application result.
    # @param [VariableTable] vtable variable table for the evaluation
    def eval(vtable)
      left = @left.eval(vtable)
      right = @right.eval(vtable)
      left.call_pione_method(@symbol, right)
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @symbol == other.symbol
      return false unless @left == other.left
      return false unless @right == other.right
      return true
    end

    alias :eql? :==

    def hash
      @symbol.hash + @left.hash + @right.hash
    end
  end
end
