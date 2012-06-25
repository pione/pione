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
  end
end
