module Pione
  module Parser
    # FeatureExpr is a set of parser atoms for feature expressions.
    module FeatureExpr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      # @!attribute [r] atomic_feature
      #   +atomic_feature+ matches all atomic features.
      #   @return [Parslet::Atoms::Entity] +atomic_feature+ atom
      #   @example
      #     # requisite feature
      #     +X
      #   @example
      #     # blocking feature
      #     -X
      #   @example
      #     # preferred feature
      #     ?X
      #   @example
      #     # possible feature
      #     ^X
      #   @example
      #     # restrictive feature
      #     !X
      #   @example
      #     # empty feature
      #     *
      #   @example
      #     # boundless feature
      #     @
      rule(:atomic_feature) {
        ( (plus.as(:operator) >> identifier.as(:symbol)) |
          (minus.as(:operator) >> identifier.as(:symbol)) |
          (question.as(:operator) >> identifier.as(:symbol)) |
          (hat.as(:operator) >> identifier.as(:symbol)) |
          (exclamation.as(:operator) >> identifier.as(:symbol)) |
          (asterisk.as(:symbol)) |
          (atmark.as(:symbol))
         ).as(:atomic_feature)
      }

      # @!attribute [r] feature_expr
      #   +feature_expr+ matches all features.
      #   @return [Parslet::Atoms::Entity] +feature_expr+ atom
      #   @example
      #     # atomic feature
      #     +X
      #   @example
      #     # feature conjunction
      #     +X & +Y
      #   @example
      #     # feature disjunction
      #     +X | +Y
      rule(:feature_expr) {
        (feature_conjunction |
         feature_disjunction |
         feature_element).as(:feature_expr)
      }

      # @!attribute [r] feature_element
      #   +feature_element+ matches all features.
      #   @return [Parslet::Atoms::Entity] +feature_element+ atom
      #   @example
      #     +X
      #   @example
      #     # feature with parethese
      #     (+X)
      rule(:feature_element) {
        atomic_feature |
        lparen >> feature_expr >> rparen
      }

      # @!attribute [r] feature_conjunction
      #   +feature_conjunction+ matches feature conjunction.
      #   @return [Parslet::Atoms::Entity] +feature_conjunction+ atom
      #   @example
      #     +X & +Y
      rule(:feature_conjunction) {
        (feature_element.as(:left) >>
         space? >>
         ampersand >>
         space? >>
         feature_expr.as(:right)
         ).as(:feature_conjunction)
      }

      # @!attribute [r] feature_disjunction
      #   +feature_disjunction+ matches feature disjunction.
      #   @return [Parslet::Atoms::Entity] +feature_disjunction+ atom
      #   @example
      #     +X | +Y
      rule(:feature_disjunction) {
        (feature_element.as(:left) >>
         space? >>
         vbar >>
         space? >>
         feature_expr.as(:right)
         ).as(:feature_disjunction)
      }
    end
  end
end
