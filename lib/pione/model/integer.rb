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
        "#<PioneInteger %s>" % @value
      end

      # @api private
      alias :to_s :inspect
    end

    class PioneIntegerSequence < BasicSequence
      set_pione_model_type TypeInteger
      set_element_class PioneInteger

      def value
        @value ||= @elements.inject(0){|n, elt| n + elt.value}
      end

      def textize
        "<ISeq [%s]>" % @elements.map{|x| x.textize}.join(",")
      end
    end

    TypeInteger.instance_eval do
      define_pione_method(">", [TypeInteger], TypeBoolean) do |rec, other|
        sequential_pred2(rec, other) do |rec_elt, other_elt|
          rec_elt.value > other_elt.value
        end
      end

      define_pione_method(">=", [TypeInteger], TypeBoolean) do |rec, other|
        PioneBooleanSequence.new(
          [PioneBoolean.new(rec.call_pione_method(">", other).value || rec.call_pione_method("==", other).value)]
        )
      end

      define_pione_method("<", [TypeInteger], TypeBoolean) do |rec, other|
        sequential_pred2(rec, other) do |rec_elt, other_elt|
          rec_elt.value < other_elt.value
        end
      end

      define_pione_method("<=", [TypeInteger], TypeBoolean) do |rec, other|
        PioneBooleanSequence.new(
          [PioneBoolean.new(
              rec.call_pione_method("<", other).value ||
              rec.call_pione_method("==", other).value
          )]
        )
      end

      define_pione_method("+", [TypeInteger], TypeInteger) do |rec, other|
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value + other_elt.value
        end
      end

      define_pione_method("-", [TypeInteger], TypeInteger) do |rec, other|
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value - other_elt.value
        end
      end

      define_pione_method("*", [TypeInteger], TypeInteger) do |rec, other|
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value * other_elt.value
        end
      end

      define_pione_method("%", [TypeInteger], TypeInteger) do |rec, other|
        # TODO: zero division error
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value % other_elt.value
        end
      end

      define_pione_method("/", [TypeInteger], TypeInteger) do |rec, other|
        # TODO: zero division error
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value / other_elt.value
        end
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        sequential_map1(TypeString, rec) {|elt| elt.value.to_s}
      end

      define_pione_method("as_integer", [], TypeInteger) do |rec|
        rec
      end

      define_pione_method("as_float", [], TypeFloat) do |rec|
        sequential_map1(TypeFloat, rec) {|elt| elt.value.to_f}
      end

      define_pione_method("next", [], TypeInteger) do |rec|
        sequential_map1(TypeInteger, rec) {|elt| elt.value.next}
      end

      define_pione_method("prev", [], TypeInteger) do |rec|
        sequential_map1(TypeInteger, rec) {|elt| elt.value.pred}
      end

      define_pione_method("even?", [], TypeBoolean) do |rec|
        sequential_pred1(rec) {|elt| elt.value.even?}
      end

      define_pione_method("odd?", [], TypeBoolean) do |rec|
        sequential_pred1(rec) {|elt| elt.value.odd?}
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
