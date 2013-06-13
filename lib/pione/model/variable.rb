module Pione
  module Model
    # Variable represent variable name objects. A variable object can evaluates
    # its value with the variable table.
    class Variable < Callable
      set_pione_model_type TypeSequence

      # variable name
      attr_reader :name

      # true if the variable is user parameter
      attr_reader :user_param

      # parameter tyep
      attr_reader :param_type

      # Create a variable with name.
      #
      # @param name [String]
      #   variable name
      def initialize(name)
        @name = name.to_s
        @toplevel = nil
        @user_param = nil
        @param_type = nil
        super()
      end

      # Evaluate self variable name in the table and returns it. Return self if
      # the variable name is unbound in the table.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        val = vtable.get(self)
        raise UnboundVariableError.new(self) if val.nil?
        return val
      end

      # Return true because variable is a variable.
      #
      # @return [Boolean]
      #   true
      def include_variable?
        true
      end

      # Set truth of toplevel variable.
      def set_toplevel(b)
        @toplevel = b
      end

      # Set truth of user parameter.
      def set_user_param(b)
        @user_param = b
      end

      # Set the parameter type.
      #
      # @param type [Symbol]
      #   :advanced or :basic
      def set_param_type(type)
        @param_type = type
      end

      # Return true if the variable is defined in toplevel.
      #
      # @return [Boolean]
      #   true if the variable is defined in toplevel
      def toplevel?
        @toplevel
      end

      # @api private
      def textize
        "$%s" % @name
      end

      # Compare with other variable.
      #
      # @api private
      def <=>(other)
        unless other.kind_of?(self.class)
          raise ArgumentError.new(other)
        end
        @name <=> other.name
      end

      # Return true if other is a variable object which name is same as myself.
      #
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
        "#<Variable %s>" % @name.inspect
      end
      alias :to_s :inspect
    end

    # class VariableSequence < Sequence
    #   set_pione_model_type TypeSequence
    #   set_element_class Variable
    # end
  end
end
