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

    class PioneFloatSequence < BasicSequence
      set_pione_model_type TypeFloat
      set_element_class PioneFloat

      def value
        @value ||= @elements.inject(0.0){|n, elt| n + elt.value}
      end
    end

    TypeFloat.instance_eval do
      define_pione_method(">", [TypeFloat], TypeBoolean) do |rec, other|
        PioneBooleanSequence.new([PioneBoolean.new(rec.value > other.value)])
      end

      define_pione_method("<", [TypeFloat], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec.value < other.value)
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
        sequential_map1(TypeInteger, rec) do |elt|
          elt.value.to_s
        end
      end

      define_pione_method("as_int", [], TypeInteger) do |rec|
        sequential_map1(TypeInteger, rec) do |elt|
          elt.value.to_i
        end
      end

      define_pione_method("as_float", [], TypeFloat) do |rec|
        rec
      end
    end
  end
end
