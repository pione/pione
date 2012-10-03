module Pione::Model
  # Assignment represents a value assignment for variable.
  # @example
  #   # assigning a string
  #   $X := "a"
  #   # => Assignment.new(Variable.new('X'), PioneString.new('a'))
  # @example
  #   # assigning a variable value
  #   $X := $Y
  #   # => Assignment.new(Variable.new('X'), Variable.new('Y'))
  class Assignment < PioneModelObject
    set_pione_model_type TypeAssignment

    # Returns the variable part of assignment.
    attr_reader :variable

    # Returns the expression part of assignment.
    attr_reader :expr

    # Creates an assignment.
    # @param [Variable] variable
    #   variable part of assignment
    # @param [PioneModelObject] expr
    #   expression part of assignment
    def initialize(variable, expr)
      check_argument_type(variable, Variable)
      check_argument_type(expr, PioneModelObject)
      @variable = variable
      @expr = expr
      super()
    end

    # Evaluates the assignment. This method updates the variable table with the
    # variable and expression. The expression is pushed into the table directory
    # as it is because of lazy evaluation.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [PioneModelObject]
    #   self
    def eval(vtable)
      vtable.set(@variable, @expr)
    end

    def set_toplevel(b)
      @variable.set_toplevel(b)
    end

    # Returns true if the assignment is defined in toplevel.
    # @return [Boolean]
    #   true if the assignment is defined in toplevel
    def toplevel?
      @variable.toplevel?
    end

    # Returns false because assignment form is complex(pair of variable and
    # expression).
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

    # Returns true if other is a variable object which name is same as myself.
    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      @variable == other.variable && @expr == other.expr
    end

    alias :eql? :"=="

    # @api private
    def hash
      @variable.hash + @expr.hash
    end
  end
end
