module Pione
  module Lang
    # PioneFloat represents float values in PIONE system.
    class PioneFloat < SimplePiece
      piece_type_name "Float"
    end

    class FloatSequence < OrdinalSequence
      set_pione_type TypeFloat
      piece_class PioneFloat

      def value
        @value ||= pieces.inject(0.0){|f, piece| f + piece.value}
      end
    end

    TypeFloat.instance_eval do
      define_pione_method(">", [TypeFloat], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value > other_piece.value
        end
      end

      define_pione_method(">=", [TypeFloat], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value >= other_piece.value
        end
      end

      define_pione_method("<", [TypeFloat], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value < other_piece.value
        end
      end

      define_pione_method("<=", [TypeFloat], TypeBoolean) do |env, rec, other|
        BooleanSequence.map2(rec, other) do |rec_piece, other_piece|
          rec_piece.value <= other_piece.value
        end
      end

      define_pione_method("+", [TypeFloat], TypeFloat) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value + other_piece.value
        end
      end

      define_pione_method("-", [TypeFloat], TypeFloat) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value - other_piece.value
        end
      end

      define_pione_method("*", [TypeFloat], TypeFloat) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value * other_piece.value
        end
      end

      define_pione_method("%", [TypeFloat], TypeFloat) do |env, rec, other|
        # TODO: zero division error
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value % other_piece.value
        end
      end

      define_pione_method("/", [TypeFloat], TypeFloat) do |env, rec, other|
        # TODO: zero division error
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value / other_piece.value
        end
      end

      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequence.map(rec) {|piece| piece.value.to_s}
      end

      # Convert to integer(by truncate).
      define_pione_method("as_integer", [], TypeInteger) do |env, rec|
        IntegerSequence.map(rec) {|piece| piece.value.truncate}
      end

      # Return the receiver as is.
      define_pione_method("as_float", [], TypeFloat) do |env, rec|
        rec
      end

      # sin : float
      define_pione_method("sin", [], TypeFloat) do |env, rec|
        rec.map {|piece| Math.sin(piece.value)}
      end

      # cos : float
      define_pione_method("cos", [], TypeFloat) do |env, rec|
        rec.map {|piece| Math.cos(piece.value)}
      end

      # abs : float
      define_pione_method("abs", [], TypeFloat) do |env, rec|
        rec.map {|piece| piece.value.abs}
      end
    end
  end
end
