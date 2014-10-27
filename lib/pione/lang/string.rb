module Pione
  module Lang
    # PioneString is a string value in PIONE system.
    class PioneString < SimplePiece
      piece_type_name "String"

      # Expand embeded expressions.
      def eval(env)
        set(value: Util::EmbededExprExpander.expand(env, value))
      end
    end

    class StringSequence < OrdinalSequence
      set_pione_type TypeString
      piece_class PioneString

      # Return a string that is joined pieces string.
      def value
        @__value__ ||= pieces.map{|piece| piece.value}.join
      end

      def textize
        "(<s>%s)" % pieces.map {|piece| '"%s"' % piece.value}.join("|")
      end
    end

    TypeString.instance_eval do
      # Concatenate strings.
      define_pione_method("+", [TypeString], TypeString) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          rec_piece.value + other_piece.value
        end
      end

      # Return the receiver as is.
      define_pione_method("as_string", [], TypeString) do |env, rec|
        rec
      end

      # Convert to integer.
      define_pione_method("as_integer", [], TypeInteger) do |env, rec|
        IntegerSequence.map(rec) {|piece| piece.value.to_i}
      end

      # Convert to float.
      define_pione_method("as_float", [], TypeFloat) do |env, rec|
        FloatSequence.map(rec) {|piece| piece.value.to_f}
      end

      # Convert to data expression.
      define_pione_method("as_data_expr", [], TypeDataExpr) do |env, rec|
        DataExprSequence.map(rec) {|piece| piece.value}
      end

      # Count characters in the string.
      define_pione_method("count", [], TypeInteger) do |env, rec|
        IntegerSequence.map(rec) {|piece| piece.value.size}
      end

      # Return true if the string includes the target.
      define_pione_method("include?", [TypeString], TypeBoolean) do |env, rec, target|
        BooleanSequence.map2(rec, target) do |rec_piece, target_piece|
          rec_piece.value.include?(target_piece.value)
        end
      end

      # Return substring from the position to the length.
      define_pione_method("substring", [TypeInteger, TypeInteger], TypeString) do |env, rec, nth, len|
        rec.map3(nth, len) do |rec_piece, nth_piece, len_piece|
          rec_piece.value[nth_piece.value-1, len_piece.value]
        end
      end

      # insert : (pos : integer) -> (other : string) -> string
      define_pione_method("insert", [TypeInteger, TypeString], TypeString) do |env, rec, pos, other|
        rec.map3(pos, other) do |rec_piece, pos_piece, other_piece|
          rec_piece.value.clone.insert(pos_piece.value-1, other_piece.value)
        end
      end

      # join : string
      define_pione_method("join", [], TypeString) do |env, rec|
        rec.call_pione_method(env, "join", [StringSequence.of(rec.separator)])
      end

      # join : (sep : string) -> string
      define_pione_method("join", [TypeString], TypeString) do |env, rec, sep|
        rec.map_by(sep) do |sep_piece|
          rec.pieces.map{|piece| piece.value}.join(sep_piece.value)
        end
      end

      # author : string
      # FIXME
      define_pione_method("author", [], TypeString) do |env, rec|
        rec.set_annotation_type(:author)
      end

      define_pione_method("PackageName", [], TypeString) do |env, rec|
        rec.set_annotation_type("PackageName")
      end

      define_pione_method("Editor", [], TypeString) do |env, rec|
        rec.set_annotation_type("Editor")
      end

      define_pione_method("Tag", [], TypeString) do |env, rec|
        rec.set_annotation_type("Tag")
      end

      define_pione_method("ScenarioName", [], TypeString) do |env, rec|
        rec.set_annotation_type("ScenarioName")
      end

      define_pione_method("ParamSet", [], TypeString) do |env, rec|
        rec.set_annotation_type("ParamSet")
      end
    end
  end
end
