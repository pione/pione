module Pione::Model
  class PioneFloat < PioneModelObject
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def pione_model_type
      TypeFloat
    end

    def to_ruby
      return @value
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @value == other.value
    end

    alias :eql? :==

    def hash
      @value.hash
    end
  end

  TypeFloat.instance_eval do
    define_pione_method("==", [TypeFloat], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value == other.value)
    end

    define_pione_method("!=", [TypeFloat], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method(">", [TypeFloat], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value > other.value)
    end

    define_pione_method(">=", [TypeFloat], TypeBoolean) do |rec, other|
      PioneBoolean.or(rec.call_pione_method(">", other),
                      rec.call_pione_method("==", other))
    end

    define_pione_method("<", [TypeFloat], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value < other.value)
    end

    define_pione_method("<=", [TypeFloat], TypeBoolean) do |rec, other|
      PioneBoolean.or(rec.call_pione_method("<", other),
                      rec.call_pione_method("==", other))
    end

    define_pione_method("+", [TypeFloat], TypeFloat) do |rec, other|
      PioneFloat.new(rec.value + other.value)
    end

    define_pione_method("-", [TypeFloat], TypeFloat) do |rec, other|
      PioneFloat.new(rec.value - other.value)
    end

    define_pione_method("*", [TypeFloat], TypeFloat) do |rec, other|
      PioneFloat.new(rec.value * other.value)
    end

    define_pione_method("%", [TypeFloat], TypeFloat) do |rec, other|
      # TODO: zero division error
      PioneFloat.new(rec.value % other.value)
    end

    define_pione_method("/", [TypeFloat], TypeFloat) do |rec, other|
      # TODO: zero division error
      PioneFloat.new(rec.value / other.value)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.value.to_s)
    end

    define_pione_method("as_int", [], TypeInteger) do |rec|
      PioneInteger(rec.value.to_i)
    end

    define_pione_method("as_float", [], TypeFloat) do |rec|
      rec
    end
  end
end
