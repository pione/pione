module Pione
  module Lang
    # TicketExpr is a ticket expression as alternative input or output
    # conditions of rules for serial processing.
    #
    # @example Serial process of rule A and B by tickets in PIONE flow rule
    #   Rule Main
    #     input '*.in'
    #     output '*.out'
    #   Flow
    #     rule A ==> <T>
    #     <T> ==> rule B
    #   End
    class TicketExpr < Piece
      piece_type_name "TicketExpr"
      member :name

      # Convert to text string.
      def textize
        "<%s>" % name
      end
    end

    # TicketExprSequence is a ordinal sequence of ticket expressions.
    class TicketExprSequence < OrdinalSequence
      set_pione_type TypeTicketExpr
      piece_class TicketExpr

      # Return ticket names of all elements in the sequence.
      def names
        pieces.map {|piece| piece.name}
      end
    end

    TypeTicketExpr.instance_eval do
      # Update ticket condition of the other by adding receiver tickets
      define_pione_method("==>", [TypeRuleExpr], TypeRuleExpr) do |env, rec, other|
        other.map do |piece|
          piece.set(input_tickets: piece.input_tickets + rec)
        end
      end

      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequence.map(rec) {|piece| piece.textize}
      end
    end
  end
end
