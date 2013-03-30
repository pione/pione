module Pione
  module Model
    # PioneInteger represents integer value in PIONE system.
    class PioneInteger < BasicModel
      set_pione_model_type TypeInteger

      attr_reader :value

      # Create a integer value in PIONE system.
      #
      # @param value [Integer]
      #   value in ruby
      def initialize(value)
        @value = value
        super()
      end

      # @api private
      def task_id_string
        "Integer<#{@value}>"
      end

      # @api private
      def textize
        @value.to_s
      end

      # Return the ruby's value.
      #
      # @return [Integer]
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

      # @api private
      def inspect
        "#<Pione::Model::PioneInteger @value=%s>" % @value.inspect
      end

      # @api private
      alias :to_s :inspect
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
        PioneInteger.new(rec.value / other.value)
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
end

# Integer extention for PIONE.
class Integer
  # Returns the PIONE's value.
  def to_pione
    PioneInteger.new(self)
  end
end
