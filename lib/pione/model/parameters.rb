module Pione
  module Model
    # Parameters is a PIONE mode class for parameters.
    class Parameters < BasicModel
      # InvalidParameter is raised when you specify invalid parameter.
      class InvalidParameter < TypeError
        # Create a error.
        #
        # @param [Object] key
        #   specified key
        def initialize(key)
          @key = key
        end

        # @api private
        def message
          "invalid parameter key: %s" % [@key.inspect]
        end
      end

      # InvalidArgument is raised when you specify invalid argument.
      class InvalidArgument < TypeError
        # Create a error.
        #
        # @param [Object] val
        #   specified value
        def initialize(val)
          @val = val
        end

        # @api private
        def message
          "invalid argument value: %s" % [@val.inspect]
        end
      end

      class << self
        # Create a empty parameters object.
        #
        # @return [Parameters]
        #   empty parameters
        def empty
          self.new({})
        end

        # Merge arguments' parameters.
        #
        # @param list [Array<Parameters>]
        #   merge target elements
        # @return [Parameters]
        #   merged result
        def merge(*list)
          new_params = empty
          list.each do |params|
            new_params = new_params.merge(params)
          end
          return new_params
        end
      end

      attr_reader :data
      set_pione_model_type TypeParameters

      # Create a parameters object.
      #
      # @param [Hash{Variable => BasicModel}] data
      #   parameters data table
      def initialize(data)
        raise TypeError.new(data) unless data.kind_of?(Hash)
        data.each do |key, val|
          raise InvalidParameter.new(key) unless key.kind_of?(Variable)
          raise InvalidArgument.new(val) unless val.kind_of?(BasicModel)
        end
        @data = data
        super()
      end

      # Evaluate the object with variable table.
      #
      # @param vtable [VariableTable]
      #   variable tabale for evaluation
      # @return [BasicModel]
      #   evaluated result
      def eval(vtable)
        return self.class.empty if empty?
        data = @data.map{|key, val| [key, val.eval(vtable)]}.flatten(1)
        self.class.new(Hash[*data])
      end

      # Return true if parameters include variables.
      #
      # @return [Boolean]
      #   true if parameters include variables
      def include_variable?
        @data.any? {|_, val| val.include_variable?}
      end

      # @api private
      def textize
        "{" + @data.map{|k,v| "%s:%s" % [k.textize[1..-1], v.textize]}.join(", ") + "}"
      end

      # Return value of parameter name.
      #
      # @param name [String]
      #   parameter name to get the value
      # @return [BasicModel]
      #   the value
      def [](name)
        @data[Variable.new(name)]
      end

      # Return the value corresponding to the parameter name. Raises an error
      # when the parameter name is kind of a variable.
      #
      # @param name [Variable]
      #   variable to get the value
      # @return [BasicModel]
      #   the value
      def get(name)
        raise InvalidParameter.new(name) unless name.kind_of?(Variable)
        @data[name]
      end

      # Add the parameter value and return new parameters.
      #
      # @param name [Variable]
      #   variable
      # @param value [BasicModel]
      #   value
      # @return [Parameters]
      #   new parameters with the parameter
      def set(name, value)
        raise InvalidParameter.new(name) unless name.kind_of?(Variable)
        raise InvalidArgument.new(value) unless value.kind_of?(BasicModel)
        self.class.new(@data.merge({name => value}))
      end

      # Add the parameter value.
      #
      # @param name [Variable]
      #   variable
      # @param value [BasicModel]
      #   value
      # @return [void]
      def set!(name, value)
        raise InvalidParameter.new(name) unless name.kind_of?(Variable)
        raise InvalidArgument.new(value) unless value.kind_of?(BasicModel)
        @data.merge!({name => value})
      end

      # Add the parameter value safety and return new parameters.
      #
      # @param name [Variable]
      #   variable
      # @param value [BasicModel]
      #   vlaue
      # @return [Parameters]
      #   new parameters with the parameter
      def set_safety(name, value)
        if not(@data.has_key?(name)) or @data[name].kind_of?(UndefinedValue)
          set(name, value)
        end
      end

      # Add the parameter value safety.
      #
      # @param name [Variable]
      #   variable
      # @param value [BasicModel]
      #   value
      # @return [void]
      def set_safety!(name, value)
        if not(@data.has_key?(name)) or @data[name].kind_of?(UndefinedValue)
          set!(name, value)
        end
      end

      # Delete the parameter by name.
      #
      # @param name [Variable]
      #   target's name
      # @return [Parameters]
      #   new parameters that deleted the target
      def delete(name)
        raise InvalidParameter.new(name) unless name.kind_of?(Variable)
        new_data = @data.clone
        new_data.delete(name)
        self.class.new(new_data)
      end

      # Return true if the parameters is empty.
      #
      # @return [Boolean]
      #   true if the parameters is empty
      def empty?
        @data.empty?
      end

      # Update parameters with the argument and return new parameters with it.
      #
      # @param other [BasicModel]
      #   merge target
      # @return [Parameters]
      #   new parameters that merged the target
      def merge(other)
        case other
        when Parameters
          self.class.new(@data.merge(other.data))
        when Variable
          self.class.new(@data.merge({other => UndefinedValue.new}))
        when Assignment
          self.class.new(@data.merge({other.variable => other.expr}))
        else
          raise TypeError.new(other)
        end
      end

      # Update parameters with the argument destructively.
      #
      # @param [BasicModel] other
      #   merge target
      # @return [void]
      def merge!(other)
        case other
        when Parameters
          @data.merge!(other.data)
        when Variable
          @data.merge!({other => UndefinedValue.new})
        when Assignment
          @data.merge!({other.variable => other.expr})
        else
          raise TypeError.new(other)
        end
      end

      # Convert into variable table.
      #
      # @return [VariableTable]
      #   variable table which values are same as the parameters.
      def as_variable_table
        VariableTable.new(@data)
      end

      # Return key list.
      #
      # @return [Array<Variable>]
      #   parameter key list
      def keys
        @data.keys.sort
      end

      # @api private
      def string_form
        "{" + @data.map{|k,v| "#{k}: #{v}"}.join(", ") + "}"
      end

      # @api private
      def to_json(*args)
        @data.to_json(*args)
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @data == other.data
      end

      alias :eql? :"=="

      # @api private
      def hash
        @data.hash
      end
    end

    TypeParameters.instance_eval do
      define_pione_method('==', [TypeParameters], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec.data == other.data)
      end

      define_pione_method("!=", [TypeParameters], TypeBoolean) do |rec, other|
        PioneBoolean.not(rec.call_pione_method("==", other))
      end

      define_pione_method("[]", [TypeString], TypeAny) do |rec, name|
        rec.get(Variable.new(name.value))
      end

      define_pione_method("get", [TypeString], TypeAny) do |rec, name|
        rec.get(Variable.new(name.value))
      end

      define_pione_method(
        "set",
        [TypeString, TypeAny],
        TypeParameters
      ) do |rec, name, val|
        rec.set(Variable.new(name.value), val)
      end

      define_pione_method("empty?", [], TypeBoolean) do |rec|
        PioneBoolean.new(rec.empty?)
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        PioneString.new(rec.string_form)
      end

      define_pione_method("str", [], TypeString) do |rec|
        rec.call_pione_method("as_string")
      end
    end
  end
end
