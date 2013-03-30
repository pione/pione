module Pione
  module Model
    # PioneFloat represents float values in PIONE system.
    class PioneFloat < BasicModel
      set_pione_model_type TypeFloat

      attr_reader :value

      # Create a float value in PIONE system.
      #
      # @param value [Float]
      #    value in ruby
      def initialize(value)
        @value = value
        super()
      end

      # @api private
      def textize
        "#PioneFloat{%s}" % @value
      end

      # Return ruby's value.
      #
      # @return [Float]
      #   ruby's value
      def to_ruby
        return @value
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @value == other.value
      end

      alias :eql? :"=="

      # @api private
      def hash
        @value.hash
      end
    end

    TypeFloat.instance_eval do
      # Return true if the other equals self.
      #
      # @return [PioneBoolean]
      #   true if the other equals self
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
        PioneInteger.new(rec.value.to_i)
      end

      define_pione_method("as_float", [], TypeFloat) do |rec|
        rec
      end
    end
  end
end
