module Pione::Model
  class Parameters < PioneModelObject
    class InvalidParameter < TypeError
      def initialize(key)
        @key = key
      end

      def message
        "invalid parameter key: %s" % [@key.inspect]
      end
    end

    class InvalidArgument < TypeError
      def initialize(val)
        @val = val
      end

      def message
        "invalid argument value: %s" % [@val.inspect]
      end
    end

    attr_reader :data
    set_pione_model_type TypeParameters

    def initialize(data)
      raise TypeError.new(data) unless data.kind_of?(Hash)
      data.each do |key, val|
        raise InvalidParameter.new(key) unless key.kind_of?(Variable)
        raise InvalidArgument.new(val) unless val.kind_of?(PioneModelObject)
      end
      @data = data
      super()
    end

    def self.empty
      self.new({})
    end

    def self.merge(*list)
      new_params = empty
      list.each do |params|
        new_params = new_params.merge(params)
      end
      return new_params
    end

    def pione_model_type
      TypeParameters
    end

    def eval(vtable)
      return self.class.empty if empty?
      data = @data.map{|key, val| [key, val.eval(vtable)]}.flatten(1)
      self.class.new(Hash[*data])
    end

    def include_variable?
      @data.any? {|_, val| val.include_variable?}
    end

    def textize
      "{" + @data.map{|k,v| "%s:%s" % [k.textize, v.textize]}.join(", ") + "}"
    end

    def [](name)
      @data[Variable.new(name)]
    end

    def get(name)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      @data[name]
    end

    def set(name, value)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      raise InvalidArgument.new(value) unless value.kind_of?(PioneModelObject)
      self.class.new(@data.merge({name => value}))
    end

    def delete(name)
      raise InvalidParameter.new(name) unless name.kind_of?(Variable)
      new_data = @data.clone
      new_data.delete(name)
      self.class.new(new_data)
    end

    def clear
      self.class.new({})
    end

    def empty?
      @data.empty?
    end

    # Updates parameters with the argument and return new parameters with it.
    def merge(other)
      self.class.new(@data.merge(other.data))
    end

    # Updates parameters with the argument destructively.
    def merge!(other)
      @data.merge!(other.data)
    end

    def as_variable_table
      VariableTable.new(@data)
    end

    def values
      @data.keys.sort
    end

    def string_form
      "{" + @data.map{|k,v| "#{k}: #{v}"}.join(", ") + "}"
    end

    def to_json(*args)
      @data.to_json(*args)
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @data == other.data
    end

    alias :eql? :==

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

    define_pione_method("clear", [], TypeParameters) do |rec|
      rec.clear
    end

    define_pione_method("empty?", [], TypeBoolean) do |rec|
      PioneBoolean.new(rec.empty?)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.string_form)
    end
  end
end
