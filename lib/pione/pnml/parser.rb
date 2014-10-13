module Pione
  module PNML
    class Parser < Parslet::Parser
      include Util::ParsletParserExtension
      include Lang::CommonParser
      include Lang::LiteralParser
      include Lang::ExprParser
      include Lang::ContextParser
      include Lang::ConditionalBranchParser
      include Lang::DeclarationParser

      rule(:net_input_symbol) { str("<") }
      rule(:net_output_symbol) { str(">") }

      rule(:keyword_then) { str("then") }
      rule(:keyword_extern) { str("extern") }

      rule(:transition_keywords) {
        space? >>
        ( keyword_if | keyword_else | keyword_then |
          keyword_case | keyword_when | keyword_constraint) >>
        space?
      }

      rule(:transition_if) {space? >> keyword_if >> space?}
      rule(:transition_else) {space? >> keyword_else >> space?}
      rule(:transition_then) {space? >> keyword_then >> space?}
      rule(:transition_case) {space? >> keyword_case >> space?}
      rule(:transition_when) {space? >> keyword_when >> space?}
      rule(:transition_constraint) {space? >> keyword_constraint >> space?}

      rule(:transition_rule) {
        external_rule | internal_rule
      }

      rule(:internal_rule) {
        space? >>
        (transition_keywords >> identifier_tail_character.absent?).absent? >>
        rule_expr >>
        space?.as(:tail)
      }

      rule(:external_rule) {
        space? >> keyword_extern >> space? >>
        rule_expr.or_error("it should be rule exprssion") >>
        space?.as(:tail)
      }

      rule(:empty_place) {
        space? >> (net_input_symbol | net_output_symbol).as(:place_modifier) >> space? |
        space?
      }

      rule(:empty_transition) { space? }

      rule(:data_priority) {
        space? >>
        expr >>
        space_char.repeat(0) >>
        str("#") >> space? >> digit.repeat(1).as(:priority) >> space?
      }

      rule(:place_expr) { space? >> expr >> space? }
      rule(:place_ticket) { space? >> ticket_expr >> space? }

      rule(:place_param) {
        place_net_input_param | place_internal_param
      }

      rule(:place_internal_param) {
        space? >> strict_param_expr.as(:param) >> space?.as(:tail)
      }

      rule(:place_net_input_param) {
        space? >> net_input_symbol.as(:modifier) >> strict_param_expr.as(:param) >> space?.as(:tail)
      }

      rule(:place_file) {
        place_net_input_file | place_net_output_file | place_internal_file
      }

      rule(:place_internal_file) {
        space? >> expr >> space?.as(:tail)
      }

      rule(:place_net_input_file) {
        space? >>
        net_input_symbol.as(:place_modifier) >>
        space? >>
        expr >>
        space?.as(:tail)
      }

      rule(:place_net_output_file) {
        space? >>
        net_output_symbol.as(:place_modifier) >>
        space? >>
        expr >>
        space?.as(:tail)
      }

      rule(:place) {
        empty_place | place_file
      }
    end
  end
end
