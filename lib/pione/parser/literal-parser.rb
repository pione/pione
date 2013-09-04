module Pione
  module Parser
    # LiteralParser is a set of parser atom for literal descriptions.
    module LiteralParser
      include Parslet

      # +boolean+ matches +true+ or +false+.
      rule(:boolean) { (keyword_true | keyword_false).as(:boolean) }

      # +string+ matches strings.
      rule(:string) {
        content = (backslash >> any | dquote.absent? >> any).repeat

        (dquote.as(:header) >> content.as(:content) >> dquote!).as(:string)
      }

      # +integer+ matches integer numbers.
      rule(:integer) { number.as(:integer) }

      # +float+ matches float numbers.
      rule(:float) {
        (number >> dot >> digit.repeat(1) >> (match('[eE]') >> number!).maybe).as(:float)
      }

      # +variable+ matches PIONE variables. Be careful there is a special variable "$*".
      rule(:variable) {
        (doller.as(:header) >> (asterisk | identifier).as(:name)).as(:variable)
      }

      # +data_expr+ matches data expressions.
      rule(:data_expr) { (data_pattern | data_null).as(:data_expr) }

      # +data_pattern+ matches data pattern expressions.
      rule(:data_pattern) {
        content = (backslash >> any | squote.absent? >> any).repeat

        squote.as(:header) >> content.as(:pattern) >> squote!
      }

      # +data_null+ matches data null expression.
      rule(:data_null) { keyword_null.as(:null) }

      # +package_expr+ matches package expressions.
      rule(:package_expr) {
        (ampersand.as(:header) >> identifier.as(:identifier)).as(:package_expr)
      }

      # +rule_expr+ matches rule expressions.
      rule(:rule_expr) {
        (keywords >> identifier_tail_character.absent?).absent? >> identifier.as(:rule_expr)
      }

      # +ticket_expr+ matches ticket expression. Be careful tickets are not
      # permitted with padding between "<" and ">". This is because we avoid
      # conflicts with other operators.
      rule(:ticket_expr) {
        (less_than.as(:header) >> identifier.as(:name) >> greater_than).as(:ticket_expr)
      }

      # +parameter_set+ matches parameter sets.
      #
      # @example
      #   {abc: "a"}
      # @example
      #   {a: 1, b: 2, c: 3}
      rule(:parameter_set) {
        (lbrace.as(:header) >> padded?(parameter_set_elements.maybe.as(:elements)) >> rbrace!).as(:parameter_set)
      }

      # +parameter_set_elements+ matches elements of parameter set.
      #
      # @example
      #   a: 1, b: 2, c: 3
      rule(:parameter_set_elements) {
        parameter_set_element >> (padded?(comma) >> parameter_set_element).repeat
      }

      # +parameter_set_element+ matches each element of parameter set.
      #
      # @example
      #   a: 1
      rule(:parameter_set_element) {
        (identifier.as(:key) >> padded?(colon!) >> expr!.as(:value)).as(:parameter_set_element)
      }

      # +feature+ matches all atomic features.
      rule(:feature) {
        ( requisite_feature |
          blocking_feature |
          preferred_feature |
          possible_feature |
          restrictive_feature |
          empty_feature |
          almighty_feature
        ).as(:feature)
      }

      # +requisite_feature+ matches requisite features.
      rule(:requisite_feature) {
        (plus.as(:prefix) >> identifier.as(:name)).as(:requisite_feature)
      }

      # +blocking_feature+ matches blocking features.
      rule(:blocking_feature) {
        (minus.as(:prefix) >> identifier.as(:name)).as(:blocking_feature)
      }

      # +preferred_feature+ matches preferred features.
      rule(:preferred_feature) {
        (question.as(:prefix) >> identifier.as(:name)).as(:preferred_feature)
      }

      # +possible_feature+ matches possible features.
      rule(:possible_feature) {
        (hat.as(:prefix) >> identifier.as(:name)).as(:possible_feature)
      }

      # +restrictive_feature+ matches restrictive features.
      rule(:restrictive_feature) {
        (exclamation.as(:prefix) >> identifier.as(:name)).as(:restrictive_feature)
      }

      # +empty_feature+ matches empty features.
      rule(:empty_feature) {
        ((asterisk >> asterisk).absent? >> asterisk.as(:symbol)).as(:empty_feature)
      }

      # +almighty_feature+ matches almighty features.
      rule(:almighty_feature) {
        (asterisk >> asterisk).as(:symbol).as(:almighty_feature)
      }
    end
  end
end
