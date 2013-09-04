module Pione
  module Model
    # RuleExpr is a referential expression of rule definition that consists of
    # rule name and pakcage id.
    class RuleExpr < Piece
      piece_type_name "RuleExpr"
      member :name
      member :package_id
      member :param_sets, default: ParameterSetSequence.of(ParameterSet.new)
      member :input_tickets, default: TicketExprSequence.new
      member :output_tickets, default: TicketExprSequence.new
    end

    # RuleExprSequence is a ordinal sequence of rule expressions.
    class RuleExprSequence < OrdinalSequence
      pione_type TypeRuleExpr
      piece_class RuleExpr
    end

    TypeRuleExpr.instance_eval do
      # Set parameters.
      define_pione_method("param", [TypeParameterSet], TypeRuleExpr) do |env, rec, param|
        # evaluate arguments
        _param = param.eval(env)

        # update pieces with new parameters
        rec.map {|piece| piece.set(param_sets: _param)}
      end

      define_pione_method("as_string", [], TypeString) do |env, rec|
        StringSequence.map(rec) {|piece| piece.textize}
      end

      define_pione_method("input_tickets", [], TypeTicketExpr) do |env, rec|
        tickets = rec.pieces.map {|piece| piece.input_tickets}
        tickets.inject {|res, t| res + t}
      end

      define_pione_method("output_tickets", [], TypeTicketExpr) do |env, rec|
        tickets = rec.pieces.map {|piece| piece.output_tickets}
        tickets.inject {|res, t| res + t}
      end

      # Update ticket condition of receiver by the ticket.
      define_pione_method("==>", [TypeTicketExpr], TypeRuleExpr) do |env, rec, tickets|
        # setup ticket conditions
        rec.map do |piece|
          piece.set(output_tickets: piece.output_tickets + tickets)
        end
      end

      # Update ticket condtion of receiver and other by anonymous ticket.
      define_pione_method(">>>", [TypeRuleExpr], TypeRuleExpr) do |env, rec, other|
        # create an anonymous ticket
        tickets = TicketExprSequence.of(Util::UUID.generate)

        # setup ticket conditions
        left = rec.map do |rec_piece|
          rec_piece.set(output_tickets: rec_piece.output_tickets + tickets)
        end
        right = other.map do |other_piece|
          other_piece.set(input_tickets: other_piece.input_tickets + tickets)
        end

        # concat sequence
        left + right
      end
    end
  end
end
