module Pione::Model
  # Variable represent variable name objects. A variable object can evaluates
  # its value with the variable table.
  class Variable < BasicModel
    set_pione_model_type TypeAny

    attr_reader :name

    # Creates a variable with name.
    # @param [String] name
    #   variable name
    def initialize(name)
      @name = name.to_s
      super()
    end

    # Evaluates self variable name in the table and returns it. Return self if
    # the variable name is unbound in the table.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [BasicModel]
    #   evaluation result
    def eval(vtable)
      val = vtable.get(self)
      raise UnboundVariableError.new(self) if val.nil?
      return val
    end

    # Returns true because variable is a variable.
    # @return [Boolean]
    #   true
    def include_variable?
      true
    end

    def set_toplevel(b)
      @toplevel = b
    end

    # Returns true if the variable is defined in toplevel.
    # @return [Boolean]
    #   true if the variable is defined in toplevel
    def toplevel?
      @toplevel
    end

    # @api private
    def task_id_string
      "Variable<#{@name}>"
    end

    # @api private
    def textize
      "$%s" % [@name]
    end

    # Comparisons with other variable.
    # @api private
    def <=>(other)
      unless other.kind_of?(self.class)
        raise ArgumentError.new(other)
      end
      @name <=> other.name
    end

    # Return true if other is a variable object which name is same as myself.
    # @api private
    def ==(other)
      other.kind_of?(self.class) && @name == other.name
    end

    alias :eql? :"=="

    # @api private
    def hash
      @name.hash
    end

    # @api private
    def inspect
      "#<Pione::Model::Variable @name=%s>" % @name.inspect
    end

    # @api private
    alias :to_s :inspect
  end
end
