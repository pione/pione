module Pione
  module Lang
    # PioneInteger represents integer value in PIONE system.
    class PioneInteger < SimplePiece
      piece_type_name "Integer"
    end

    # IntegerSequence is a sequence of PIONE integer.
    class IntegerSequence < OrdinalSequence
      set_pione_type TypeInteger
      piece_class PioneInteger

      def textize
        "(<i>%s)" % pieces.map {|piece| piece.value}.join("|")
      end
    end

    TypeInteger.instance_eval do
      define_pione_method(">", [TypeInteger], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value > other_piece.value
        end
      end

      define_pione_method(">=", [TypeInteger], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value >= other_piece.value
        end
      end

      define_pione_method("<", [TypeInteger], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value < other_piece.value
        end
      end

      define_pione_method("<=", [TypeInteger], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value <= other_piece.value
        end
      end

      define_pione_method("+", [TypeInteger], TypeInteger) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value + other_piece.value
        end
      end

      define_pione_method("-", [TypeInteger], TypeInteger) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value - other_piece.value
        end
      end

      define_pione_method("*", [TypeInteger], TypeInteger) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value * other_piece.value
        end
      end

      define_pione_method("%", [TypeInteger], TypeInteger) do |env, rec, other|
        # TODO: zero division error
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value % other_piece.value
        end
      end

      define_pione_method("/", [TypeInteger], TypeInteger) do |env, rec, other|
        # TODO: zero division error
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value / other_piece.value
        end
      end

      # Convert to integer.
      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequence.map(rec) {|piece| piece.value.to_s}
      end

      # Return itself.
      define_pione_method("as_integer", [], TypeInteger) do |env, rec|
        rec
      end

      # Convert to float.
      define_pione_method("as_float", [], TypeFloat) do |env, rec|
        FloatSequence.map(rec) {|piece| piece.value.to_f}
      end

      # Return the next number.
      define_pione_method("next", [], TypeInteger) do |env, rec|
        rec.map {|piece| piece.value.next}
      end

      # Return the previous number.
      define_pione_method("prev", [], TypeInteger) do |env, rec|
        rec.map {|piece| piece.value.pred}
      end

      # Return true if it is even.
      define_pione_method("even?", [], TypeBoolean) do |env, rec|
        BooleanSequence.map(rec) {|piece| piece.value.even?}
      end

      # Return true if it is odd.
      define_pione_method("odd?", [], TypeBoolean) do |env, rec|
        BooleanSequence.map(rec) {|piece| piece.value.odd?}
      end

      # upto : *integer -> *integer
      define_pione_method("upto", [TypeInteger], TypeInteger) do |env, rec, max|
        rec.fold2(IntegerSequence.new, max) do |seq, rec_piece, max_piece|
          if rec_piece.value <= max_piece.value
            rec_piece.value.upto(max_piece.value).inject(seq) do |_seq, i|
              _seq.push(PioneInteger.new(value: i))
            end
          else
            seq
          end
        end
      end

      # downto : integer -> integer
      define_pione_method("downto", [TypeInteger], TypeInteger) do |env, rec, min|
        rec.fold2(IntegerSequence.new, min) do |seq, rec_piece, min_piece|
          if rec_piece.value >= min_piece.value
            rec_piece.value.downto(min_piece .value).inject(seq) do |_seq, i|
              _seq.push(PioneInteger.new(value: i))
            end
          else
            seq
          end
        end
      end

      # max : integer
      define_pione_method("max", [], TypeInteger) do |env, rec|
        rec.fold(rec.empty) do |seq, piece|
          if seq.pieces.size == 0 or seq.pieces.first.value < piece.value
            seq.set(pieces: [piece])
          else
            seq
          end
        end
      end

      # min : integer
      define_pione_method("min", [], TypeInteger) do |env, rec|
        rec.fold(rec.empty) do |seq, piece|
          if seq.pieces.size == 0 or seq.pieces.first.value > piece.value
            seq.set(pieces: [piece])
          else
            seq
          end
        end
      end
    end
  end
end
