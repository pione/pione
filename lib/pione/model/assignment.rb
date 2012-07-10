module Pione::Model
  # Assignment represents a value assignment for variable.
  # For example assigning a string:
  #   $X := "a"
  #   => Assignment.new(Variable.new('X'), 'a')
  #
  # For exmpale assigning a variable value:
  #   $X := $Y
  #   => Assignment.new(Variable.new('X'), Variable.new('Y'))
  class Assignment < PioneModelObject
    attr_reader :variable
    attr_reader :expr

    def initialize(variable, expr)
      @variable = variable
      @expr = expr
    end

    # Evaluates value and update the variable table with it.
    def eval(vtable)
      vtable.set(@variable, @expr.eval(vtable))
    end

    # Return true if other is a variable object which name is same as myself.
    def ==(other)
      return false unless other.kind_of?(self.class)
      @variable == other.variable && @expr == other.expr
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @name.hash
    end
  end
end
