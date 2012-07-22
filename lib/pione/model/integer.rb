module Pione::Model
  class PioneInteger < PioneModelObject
    attr_reader :value

    def initialize(value)
      @value = value
    end

    def pione_model_type
      TypeInteger
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

  TypeInteger.instance_eval do
    define_pione_method("==", [TypeInteger], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value == other.value)
    end

    define_pione_method("!=", [TypeInteger], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method(">", [TypeInteger], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value > other.value)
    end

    define_pione_method(">=", [TypeInteger], TypeBoolean) do |rec, other|
      PioneBoolean.or(rec.call_pione_method(">", other),
                      rec.call_pione_method("==", other))
    end

    define_pione_method("<", [TypeInteger], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value < other.value)
    end

    define_pione_method("<=", [TypeInteger], TypeBoolean) do |rec, other|
      PioneBoolean.or(rec.call_pione_method("<", other),
                      rec.call_pione_method("==", other))
    end

    define_pione_method("+", [TypeInteger], TypeInteger) do |rec, other|
      PioneInteger.new(rec.value + other.value)
    end

    define_pione_method("-", [TypeInteger], TypeInteger) do |rec, other|
      PioneInteger.new(rec.value - other.value)
    end

    define_pione_method("*", [TypeInteger], TypeInteger) do |rec, other|
      PioneInteger.new(rec.value * other.value)
    end

    define_pione_method("%", [TypeInteger], TypeInteger) do |rec, other|
      # TODO: zero division error
      PioneInteger.new(rec.value % other.value)
    end

    define_pione_method("/", [TypeInteger], TypeInteger) do |rec, other|
      # TODO: zero division error
      PioneIntger.new(rec.value / other.value)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.value.to_s)
    end

    define_pione_method("as_int", [], TypeInteger) do |rec|
      rec
    end

    define_pione_method("as_float", [], TypeFloat) do |rec|
      PioneFloat.new(rec.value.to_f)
    end

    define_pione_method("next", [], TypeInteger) do |rec|
      PioneInteger.new(rec.value.next)
    end

    define_pione_method("prev", [], TypeInteger) do |rec|
      PioneInteger.new(rec.value.pred)
    end

    define_pione_method("even?", [], TypeBoolean) do |rec|
      PioneBoolean.new(rec.value.even?)
    end

    define_pione_method("odd?", [], TypeBoolean) do |rec|
      PioneBoolean.new(rec.value.odd?)
    end
  end
end

class Integer
  def to_pione
    PioneInteger.new(self)
  end
end
