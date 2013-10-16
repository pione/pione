module Pione
  module Lang
    # DeclarationParser is a set of parsers for PIONE declaration setences and
    # blocks.
    module DeclarationParser
      include Parslet

      #
      # outline
      #

      # SENTENCES is a list of declarative sentences in PIONE language.
      SENTENCES = [
        :variable_binding_sentence,
        :package_binding_sentence,
        :param_sentence,
        :rule_binding_sentence,
        :constituent_rule_sentence,
        :input_sentence,
        :output_sentence,
        :feature_sentence,
        :constraint_sentence,
        :annotation_sentence,
        :expr_sentence
      ]

      # BLOCKS is a list of declaration blocks in PIONE language.
      BLOCKS = [
        :param_block,
        :flow_rule_block,
        :action_rule_block,
        :empty_rule_block
      ]

      # +declarative_sentence+ match all declarative sentences.
      rule(:declarative_sentence) {
        SENTENCES.inject(nil) {|res, elt| res ? res | send(elt) : send(elt)}
      }

      # +declarative_block+ match all declarative blocks.
      rule(:declarative_block) {
        BLOCKS.inject(nil) {|res, elt| res ? res | send(elt) : send(elt)}
      }

      # +declaration+ match all declarations.
      rule(:declaration) { declarative_sentence | declarative_block }

      #
      # sentences
      #

      # Make a parser for binding sentences.
      def binding_sentence(declarator, operator, omittable)
        binding = expr.as(:expr1) >> padded?(operator) >> expr!.as(:expr2)

        if omittable
          line((declarator.as(:declarator) >> pad).maybe >> binding)
        else
          line(declarator.as(:declarator) >> pad >> binding)
        end
      end

      # +variable_binding_sentence+ matches variable binding declarations.
      rule(:variable_binding_sentence) {
        binding_sentence(keyword_bind, binding_operator!, true).as(:variable_binding_sentence)
      }

      # +package_binding_sentence+ matches all package binding setences.
      rule(:package_binding_sentence) {
        binding_sentence(keyword_package, generating_operator!, false).as(:package_binding_sentence)
      }

      # +param_sentence+ matches parameter declarations.
      rule(:param_sentence) {
        type = (keyword_basic | keyword_advanced).as(:type)
        with_default = expr.as(:expr1) >> padded?(binding_operator) >> expr!.as(:expr2)
        without_default = expr.as(:expr1)

        line(((type >> pad).maybe >> keyword_param.as(:declarator) >> pad >> (with_default | without_default)).as(:param_sentence))
      }

      # +rule_binding_sentence+ matches rule binding declarations.
      rule(:rule_binding_sentence) {
        binding_sentence(keyword_rule, binding_operator, false).as(:rule_binding_sentence)
      }

      # +constituent_sentence+ matches constituent rule declarations.
      rule(:constituent_rule_sentence) {
        line(keyword_rule.as(:declarator) >> pad >> expr!.as(:expr)).as(:constituent_rule_sentence)
      }

      # +input_sentence+ matches input condition declarations.
      rule(:input_sentence) {
        line(keyword_input.as(:declarator) >> pad >> expr!.as(:expr)).as(:input_sentence)
      }

      # +output_sentence+ matches output condition declarations.
      rule(:output_sentence) {
        line(keyword_output.as(:declarator) >> pad >> expr!.as(:expr)).as(:output_sentence)
      }

      # +feature_sentence+ matches feature declarations.
      rule(:feature_sentence) {
        line(keyword_feature.as(:declarator) >> pad >> expr!.as(:expr)).as(:feature_sentence)
      }

      # +constraint_sentence+ matches constraint declarations.
      rule(:constraint_sentence) {
        line(keyword_constraint.as(:declarator) >> pad >> expr!.as(:expr)).as(:constraint_sentence)
      }

      # +annotation_sentence+ matches annotation declarations.
      rule(:annotation_sentence) {
        line((dot >> atmark).as(:declarator) >> pad >> expr!.as(:expr)).as(:annotation_sentence)
      }

      # +expr_sentence+ matches expression declarations(maybe this is ignored in normal contexts).
      rule(:expr_sentence) {
        ( line(question.as(:declarator) >> pad? >> expr!.as(:expr)) |
          line(expr.as(:expr))
          ).as(:expr_sentence)
      }

      #
      # blocks
      #

      # +param_block+ matches parameter declarations.
      rule(:param_block) {
        (param_block_header >> param_context.as(:context) >> param_block_footer!).as(:param_block)
      }

      # +param_block_header+ matches parameter block headers.
      rule(:param_block_header) {
        line((param_block_modifier.as(:type) >> space).maybe >> keyword_Param.as(:declarator))
      }

      # +param_block_modifier+ matches all parameter block modifiers.
      rule(:param_block_modifier) { keyword_Basic | keyword_Advanced }

      # +param_block_footer+ matches parameter declaration block footer.
      rule(:param_block_footer) { line(keyword_End) }
      rule(:param_block_footer!) { param_block_footer.or_error("it should be parameter block end") }

      # +flow_rule_block+ matches flow rule declarations.
      rule(:flow_rule_block) {
        ( rule_header >> rule_condition_context.as(:context1) >>
          line(keyword_Flow) >> flow_context.as(:context2) >> rule_footer!
        ).as(:flow_rule_block)
      }

      # +action_rule_block+ matches action rule declarations.
      rule(:action_rule_block) {
        ( rule_header >> rule_condition_context.as(:context1) >>
          line(keyword_Action) >> action_context.as(:context2) >> rule_footer!
        ).as(:action_rule_block)
      }

      # +empty_rule_block+ matches empty rule declarations.
      rule(:empty_rule_block) {
        (rule_header >> rule_condition_context.as(:context) >> rule_footer!).as(:empty_rule_block)
      }

      # +rule_header+ matches rule headers.
      rule(:rule_header) {
        line(keyword_Rule.as(:declarator) >> space >> expr!("should be rule name").as(:expr))
      }

      # +rule_footer+ matches rule end keywords.
      rule(:rule_footer) { line(keyword_End) }
      rule(:rule_footer!) { rule_footer.or_error("rule footer not found") }
    end
  end
end
