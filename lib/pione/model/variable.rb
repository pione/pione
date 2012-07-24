module Pione::Model
  # Variable represent variable name objects. A variable object can evaluates
  # its value with the variable table.
  class Variable < PioneModelObject
    attr_reader :name

    def initialize(name)
      @name = name.to_s
    end

    def pione_model_type
      TypeAny
    end

    # Evaluates self variable name in the table and returns it. Return self if
    # the variable name is unbound in the table.
    def eval(vtable)
      val = vtable.get(self)
      raise UnboundVariableError.new(self) if val.nil?
      return val
    end

    # Return true if other is a variable object which name is same as myself.
    def ==(other)
      other.kind_of?(self.class) && @name == other.name
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @name.hash
    end
  end
end
