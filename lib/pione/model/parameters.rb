module Pione::Model
  class Parameters < PioneModelObject
    attr_reader :data

    def initialize(data)
      raise ArgumentError.new(data) unless data.kind_of?(Hash)
      @data = data
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

    def eval(vtable=VariableTable.new)
      self.class.new(
        Hash.new[
          *@data.map do |key, val|
            [key, val.eval(vtable)]
          end.flatten(1)
        ]
      )
    end

    def get(name)
      @data[name]
    end

    def set(name, value)
      self.class.new(@data.merge({name => value}))
    end

    def delete(name)
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

    def merge(other)
      self.class.new(@data.merge(other.data))
    end

    def values
      @data.keys.sort
    end

    def string_form
      "{" + @data.map{|k,v| "#{k}: #{v}"}.join(", ") + "}"
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

    define_pione_method("get", [TypeString], TypeAny) do |rec, name|
      rec.get(name.value)
    end

    define_pione_method(
      "set",
      [TypeString, TypeAny],
      TypeParameters
    ) do |rec, name, val|
      rec.set(name, val)
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
