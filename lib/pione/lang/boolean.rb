module Pione
  module Lang
    # PioneBoolean representes truth value in PIONE system.
    class PioneBoolean < SimplePiece
      piece_type_name "Boolean"
    end

    # BooleanSequence is a class for sequences of boolean.
    class BooleanSequence < OrdinalSequence
      pione_type TypeBoolean
      piece_class PioneBoolean

      def value
        @__value__ ||= pieces.inject(true){|b, piece| b and piece.value}
      end

      def textize
        "(<b>%s)" % pieces.map {|piece| piece.value}.join("|")
      end
    end

    #
    # pione methods
    #

    TypeBoolean.instance_eval do
      define_pione_method("and", [TypeBoolean], TypeBoolean) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value && other_piece.value
        end
      end

      define_pione_method("or", [TypeBoolean], TypeBoolean) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value || other_piece.value
        end
      end

      # Return the receiver as is.
      define_pione_method("as_boolean", [], TypeBoolean) do |env, rec|
        rec
      end

      # Convert to integer.
      define_pione_method("as_integer", [], TypeInteger) do |env, rec|
        IntegerSequence.map(rec) {|rec| rec.value ? 1 : 0}
      end

      # Convert to float.
      define_pione_method("as_float", [], TypeFloat) do |env, rec|
        FloatSequence.map(rec) {|rec| rec.value ? 1.0 : 0.0}
      end

      # Convert to string.
      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequence.map(rec) {|piece| piece.value.to_s}
      end

      # Convert to data expression.
      define_pione_method("as_data_expr", [], TypeDataExpr) do |env, rec|
        DataExprSequence.map(rec) {|piece| rec.value.to_s}
      end

      # Reverse the truth.
      define_pione_method("not", [], TypeBoolean) do |env, rec|
        rec.map {|piece| not(piece.value)}
      end

      # Return true if every piece is true.
      define_pione_method("every?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.pieces.all?{|piece| piece.value})
      end

      # Return true if some piece are true.
      define_pione_method("any?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.pieces.any?{|piece| piece.value})
      end

      # Return true if just one piece is true.
      define_pione_method("one?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.pieces.one?{|piece| piece.value})
      end

      # Return true if every piece is false.
      define_pione_method("none?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.pieces.none?{|piece| piece.value})
      end
    end
  end
end
