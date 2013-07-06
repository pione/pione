module Pione
  module Parser
    # FeatureExprParser is a set of parser atoms for feature expressions.
    module FeatureExprParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser

      # +atomic_feature+ matches all atomic features.
      rule(:atomic_feature) {
        ( requisite_feature | blocking_feature | preferred_feature | possible_feature |
          restrictive_feature | empty_feature | boundless_feature ).as(:atomic_feature)
      }

      # +requisite_feature+ matches requisite feature expressions.
      #
      # @example requisite feature
      #   +X
      rule(:requisite_feature) { plus.as(:operator) >> identifier.as(:symbol) }

      # @example blocking feature
      #   -X
      rule(:blocking_feature) { minus.as(:operator) >> identifier.as(:symbol) }

      # @example preferred feature
      #   ?X
      rule(:preferred_feature) { question.as(:operator) >> identifier.as(:symbol) }

      # @example possible feature
      #   ^X
      rule(:possible_feature) { hat.as(:operator) >> identifier.as(:symbol) }

      # @example restrictive feature
      #   !X
      rule(:restrictive_feature) { exclamation.as(:operator) >> identifier.as(:symbol) }

      # @example empty feature
      #   *
      rule(:empty_feature) { asterisk.as(:symbol) }

      # @example boundless feature
      #   @
      rule(:boundless_feature) { atmark.as(:symbol) }

      # +feature_expr+ matches all features.
      rule(:feature_expr) {
        (feature_conjunction | feature_disjunction | feature_element).as(:feature_expr)
      }

      # +feature_element+ matches all features.
      #
      # @example
      #   +X
      # @example feature with parethese
      #   (+X)
      rule(:feature_element) { atomic_feature | lparen >> feature_expr >> rparen! }

      # +feature_conjunction+ matches feature conjunction.
      #
      # @example
      #   +X & +Y
      rule(:feature_conjunction) {
        (feature_element.as(:left) >> spaced?(ampersand) >> feature_expr.as(:right)).as(:feature_conjunction)
      }
      # +feature_disjunction+ matches feature disjunction.
      #
      # @example
      #     +X | +Y
      rule(:feature_disjunction) {
        (feature_element.as(:left) >> spaced?(vbar) >> feature_expr.as(:right)).as(:feature_disjunction)
      }
    end
  end
end
