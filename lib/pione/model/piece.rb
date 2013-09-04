module Pione
  module Model
    # Piece is a base class for all elements of sequence. You cannot write it
    # directly in PIONE language because pieces are not included in expressions.
    class Piece < StructX
      include Util::Positionable
      immutable true

      # Declare the type name of piece.
      def self.piece_type_name(name=nil)
        name ? @piece_type_name = name : @piece_type_name
      end

      forward :class, :piece_type_name

      def eval(env)
        return self
      end

      # Convert to text string.
      def textize
        args = to_h.map do |key, val|
          "%s=%s" % [key, val.kind_of?(Piece) ? val.textize : val.to_s]
        end.join(", ")
        "#%s{%s}" % [piece_type_name, args]
      end
    end

    # SimplePiece is a piece of sequence that has single value elements.
    class SimplePiece < Piece
      member :value

      def textize
        "#%s{value=%s}" % [piece_type_name, value.textize]
      end

      def inspect
        "#%s{value=%s}" % [piece_type_name, value.to_s]
      end
    end
  end
end
