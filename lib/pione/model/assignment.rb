module Pione::Model
  # Assignment represents a value assignment for variable.
  # For example assigning a string:
  #   $X := "a"
  #   => Assignment.new(Variable.new('X'), PioneString.new('a'))
  #
  # For exmpale assigning a variable value:
  #   $X := $Y
  #   => Assignment.new(Variable.new('X'), Variable.new('Y'))
  class Assignment < PioneModelObject
    attr_reader :variable
    attr_reader :expr

    def initialize(variable, expr)
      raise ArgumentError.new(variable) unless variable.kind_of?(Variable)
      raise ArgumentError.new(expr) unless expr.kind_of?(PioneModelObject)
      @variable = variable
      @expr = expr
      super()
    end

    # Evaluates value and update the variable table with it.
    def eval(vtable)
      # put expr into the table directory because of lazy evaluation
      vtable.set(@variable, @expr)
    end

    def atomic?
      false
    end

    def include_variable?
      @expr.include_variable?
    end

    def textize
      "%s:=%s" % [@variable.textize, @expr.textize]
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
