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

      #
      # symbols and keywords
      #

      rule(:symbol_net_input_data) { str("<") }
      rule(:symbol_net_output_data) { str(">") }

      rule(:keyword_then) { str("then") }
      rule(:keyword_extern) { str("extern") }

      rule(:transition_keyword) {
        keyword_if         |
        keyword_else       |
        keyword_then       |
        keyword_case       |
        keyword_when       |
        keyword_constraint |
        keyword_extern
      }

      #
      # transtion syntax
      #

      rule(:empty_transition) { space?.as(:tail) }

      rule(:keyword_transition) {
        space? >> transition_keyword >> space?.as(:tail)
      }

      rule(:if_transition) {space? >> keyword_if >> space?.as(:tail)}
      rule(:else_transition) {space? >> keyword_else >> space?.as(:tail)}
      rule(:then_transition) {space? >> keyword_then >> space?.as(:tail)}
      rule(:case_transition) {space? >> keyword_case >> space?.as(:tail)}
      rule(:when_transition) {space? >> keyword_when >> space?.as(:tail)}
      rule(:constraint_transition) {space? >> keyword_constraint >> space?.as(:tail)}

      rule(:rule_transition) {
        external_rule_transition | internal_rule_transition
      }

      rule(:external_rule_transition) {
        space? >> keyword_extern.as(:modifier) >> space? >>
        expr.or_error("it should be rule exprssion") >>
        space?.as(:tail)
      }

      rule(:internal_rule_transition) {
        space? >>
        (keyword_transition >> identifier_tail_character.absent?).absent? >>
        expr >>
        space?.as(:tail)
      }

      #
      # place syntax
      #

      rule(:data_modifier) {
        (symbol_net_input_data | symbol_net_output_data).as(:modifier)
      }

      rule(:empty_place) {
        (space? >> data_modifier >> space?.as(:tail)) | space?.as(:tail)
      }

      rule(:data_place) {
        (space? >> data_modifier >> expr_place) | expr_place
      }

      rule(:expr_place) {
        space? >> expr >> space?.as(:tail)
      }

      #
      # others
      #

      rule(:net_input_symbol) {
        space? >> symbol_net_input_data >> space?
      }

      rule(:net_output_symbol) {
        space? >> symbol_net_output_data >> space?
      }

      rule(:data_priority) {
        space? >>
        expr >>
        space_char.repeat(0) >>
        str("#") >> space? >> digit.repeat(1).as(:priority) >> space?
      }
    end
  end
end
