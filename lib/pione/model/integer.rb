module Pione
  module Model
    # PioneInteger represents integer value in PIONE system.
    class PioneInteger < Value
      # @api private
      def textize
        @value.to_s
      end

      def to_seq
        IntegerSequence.new([self])
      end
    end

    class IntegerSequence < OrdinalSequence
      set_pione_model_type TypeInteger
      set_element_class PioneInteger
      set_shortname "ISeq"
    end

    TypeInteger.instance_eval do
      define_pione_method(">", [TypeInteger], TypeBoolean) do |vtable, rec, other|
        sequential_map2(TypeBoolean, rec, other) do |rec_elt, other_elt|
          rec_elt.value > other_elt.value
        end
      end

      define_pione_method(">=", [TypeInteger], TypeBoolean) do |vtable, rec, other|
        BooleanSequence.new(
          [PioneBoolean.new(rec.call_pione_method(vtable, ">", other).value || rec.call_pione_method(vtable, "==", other).value)]
        )
      end

      define_pione_method("<", [TypeInteger], TypeBoolean) do |vtable, rec, other|
        sequential_map2(TypeBoolean, rec, other) do |rec_elt, other_elt|
          rec_elt.value < other_elt.value
        end
      end

      define_pione_method("<=", [TypeInteger], TypeBoolean) do |vtable, rec, other|
        BooleanSequence.new(
          [PioneBoolean.new(
              rec.call_pione_method(vtable, "<", other).value ||
              rec.call_pione_method(vtable, "==", other).value
          )]
        )
      end

      define_pione_method("+", [TypeInteger], TypeInteger) do |vtable, rec, other|
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value + other_elt.value
        end
      end

      define_pione_method("-", [TypeInteger], TypeInteger) do |vtable, rec, other|
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value - other_elt.value
        end
      end

      define_pione_method("*", [TypeInteger], TypeInteger) do |vtable, rec, other|
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value * other_elt.value
        end
      end

      define_pione_method("%", [TypeInteger], TypeInteger) do |vtable, rec, other|
        # TODO: zero division error
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value % other_elt.value
        end
      end

      define_pione_method("/", [TypeInteger], TypeInteger) do |vtable, rec, other|
        # TODO: zero division error
        sequential_map2(TypeInteger, rec, other) do |rec_elt, other_elt|
          rec_elt.value / other_elt.value
        end
      end

      define_pione_method("as_string", [], TypeString) do |vtable, rec|
        sequential_map1(TypeString, rec) {|elt| elt.value.to_s}
      end

      define_pione_method("as_integer", [], TypeInteger) do |vtable, rec|
        rec
      end

      define_pione_method("as_float", [], TypeFloat) do |vtable, rec|
        sequential_map1(TypeFloat, rec) {|elt| elt.value.to_f}
      end

      define_pione_method("next", [], TypeInteger) do |vtable, rec|
        sequential_map1(TypeInteger, rec) {|elt| elt.value.next}
      end

      define_pione_method("prev", [], TypeInteger) do |vtable, rec|
        sequential_map1(TypeInteger, rec) {|elt| elt.value.pred}
      end

      define_pione_method("even?", [], TypeBoolean) do |vtable, rec|
        sequential_pred1(rec) {|elt| elt.value.even?}
      end

      define_pione_method("odd?", [], TypeBoolean) do |vtable, rec|
        sequential_pred1(rec) {|elt| elt.value.odd?}
      end

      # upto : *integer -> *integer
      define_pione_method("upto", [TypeInteger], TypeInteger) do |vtable, rec, max|
        sequential_fold2(TypeInteger, rec, max) do |seq, rec_elt, max_elt|
          if rec_elt.value < max_elt.value
            rec_elt.value.upto(max_elt.value).inject(seq) do |_seq, i|
              _seq.push(PioneInteger.new(i))
            end
          else
            seq.push(rec_elt)
          end
        end
      end

      # downto : integer -> integer
      define_pione_method("downto", [TypeInteger], TypeInteger) do |vtable, rec, min|
        sequential_fold2(TypeInteger, rec, min) do |seq, rec_elt, min_elt|
          if rec_elt.value > min_elt.value
            rec_elt.value.downto(min_elt.value).inject(seq) do |_seq, i|
              _seq.push(PioneInteger.new(i))
            end
          else
            seq.push(rec_elt)
          end
        end
      end

      # max : integer
      define_pione_method("max", [], TypeInteger) do |vtable, rec|
        fold1(IntegerSequence.empty, rec) do |seq, elt|
          if seq.elements.size == 0 or seq.elements.first.value < elt.value
            elt.to_seq
          else
            seq
          end
        end
      end

      # min : integer
      define_pione_method("min", [], TypeInteger) do |vtable, rec|
        fold1(IntegerSequence.empty, rec) do |seq, elt|
          if seq.elements.size == 0 or seq.elements.first.value > elt.value
            elt.to_seq
          else
            seq
          end
        end
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
