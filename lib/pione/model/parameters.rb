module Pione::Model
  # Parameters is a PIONE mode class for parameters.
  class Parameters < PioneModelObject
    # InvalidParameter is raised when you specify invalid parameter.
    class InvalidParameter < TypeError
      # Creates a error.
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
      # Creates a error.
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
      # Creates a empty parameters object.
      # @return [Parameters]
      #   empty parameters
      def empty
        self.new({})
      end

      # Merges arguments' parameters.
      # @param [Array<Parameters>] list
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

    # Creates a parameters object.
    # @param [Hash{Variable => PioneModelObject}] data
    #   parameters data table
    def initialize(data)
      raise TypeError.new(data) unless data.kind_of?(Hash)
      data.each do |key, val|
        raise InvalidParameter.new(key) unless key.kind_of?(Variable)
        raise InvalidArgument.new(val) unless val.kind_of?(PioneModelObject)
      end
      @data = data
      super()
    end

    # Evaluates the object with variable table.
    # @param [VariableTable] vtable
    #   variable tabale for evaluation
    # @return [PioneModelObject]
    #   evaluated result
    def eval(vtable)
      return self.class.empty if empty?
      data = @data.map{|key, val| [key, val.eval(vtable)]}.flatten(1)
      self.class.new(Hash[*data])
    end

    # Returns true if parameters include variables.
    # @return [Boolean]
    #   true if parameters include variables
    def include_variable?
      @data.any? {|_, val| val.include_variable?}
    end

    # @api private
    def textize
      "{" + @data.map{|k,v| "%s:%s" % [k.textize[1..-1], v.textize]}.join(", ") + "}"
    end

    # Returns value of parameter name.
    # @param [String] name
    #   parameter name to get the value
    # @return [PioneModelObject]
    #   the value
    def [](name)
      @data[Variable.new(name)]
    end

    # Returns the value corresponding to the parameter name. Raises an error
    # when the parameter name is kind of a variable.
    # @param [Variable] name
    #   variable to get the value
    # @return [PioneModelObject]
    #   the value
    def get(name)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      @data[name]
    end

    # Adds the parameter value and return new parameters.
    # @param [Variable] name
    # @param [PioneModelObject] value
    # @return [Parameters]
    #   new parameters with the parameter
    def set(name, value)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      raise InvalidArgument.new(value) unless value.kind_of?(PioneModelObject)
      self.class.new(@data.merge({name => value}))
    end

    # Adds the parameter value.
    # @param [Variable] name
    # @param [PioneModelObject] value
    # @return [void]
    def set!(name, value)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      raise InvalidArgument.new(value) unless value.kind_of?(PioneModelObject)
      @data.merge!({name => value})
    end

    # Adds the parameter value safety and return new parameters.
    # @param [Variable] name
    # @param [PioneModelObject] value
    # @return [Parameters]
    #   new parameters with the parameter
    def set_safety(name, value)
      if not(@data.has_key?(name)) or @data[name].kind_of?(UndefinedValue)
        set(name, value)
      end
    end

    # Adds the parameter value safety.
    # @param [Variable] name
    # @param [PioneModelObject] value
    # @return [void]
    def set_safety!(name, value)
      if not(@data.has_key?(name)) or @data[name].kind_of?(UndefinedValue)
        set!(name, value)
      end
    end

    # Deletes the parameter by name.
    # @param [Variable] name
    #   target's name
    # @return [Parameters]
    #   new parameters that deleted the target
    def delete(name)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      new_data = @data.clone
      new_data.delete(name)
      self.class.new(new_data)
    end

    # Returns true if the parameters is empty.
    # @return [Boolean]
    #   true if the parameters is empty
    def empty?
      @data.empty?
    end

    # Updates parameters with the argument and return new parameters with it.
    # @param [PioneModelObject] other
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

    # Updates parameters with the argument destructively.
    # @param [PioneModelObject] other
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

    # Converts into variable table.
    # @return [VariableTable]
    #   variable table which values are same as the parameters.
    def as_variable_table
      VariableTable.new(@data)
    end

    # Returns key list.
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
  end
end
