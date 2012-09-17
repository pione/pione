module Pione::Model
  # Assignment represents a value assignment for variable.
  # @example
  #   # assigning a string:
  #   $X := "a"
  #   # => Assignment.new(Variable.new('X'), PioneString.new('a'))
  # @example
  #   # assigning a variable value:
  #   $X := $Y
  #   # => Assignment.new(Variable.new('X'), Variable.new('Y'))
  class Assignment < PioneModelObject
    # Returns variable part of the assignment.
    attr_reader :variable

    # Returns expression part of the assignment.
    attr_reader :expr

    set_pione_model_type TypeAssignment

    # Creates an assignment.
    # @param [Variable] variable
    #   head of assignment
    # @param [PioneModelObject] expr
    #   tail of assignment
    def initialize(variable, expr)
      raise ArgumentError.new(variable) unless variable.kind_of?(Variable)
      raise ArgumentError.new(expr) unless expr.kind_of?(PioneModelObject)
      @variable = variable
      @expr = expr
      super()
    end

    # Evaluates value and update the variable table with it.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    def eval(vtable)
      # put expr into the table directory because of lazy evaluation
      vtable.set(@variable, @expr)
    end

    # Returns false because assignment has complex form.
    # @return [Boolean]
    #   false
    def atomic?
      false
    end

    # Returns true if the expression part of assignment includes variable.
    # @return [Boolean]
    #   true if the expression part of assignment includes variable
    def include_variable?
      @expr.include_variable?
    end

    # @api private
    def textize
      "%s:=%s" % [@variable.textize, @expr.textize]
    end

    # Return true if other is a variable object which name is same as myself.
    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      @variable == other.variable && @expr == other.expr
    end

    alias :eql? :==

    # @api private
    def hash
      @name.hash
    end
  end
end
