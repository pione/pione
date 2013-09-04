module Pione
  module Parser
    # ConditionalBranchParser is a set of parsers for conditional branch "if" and "case".
    module ConditionalBranchParser
      include Parslet

      #
      # outline
      #

      # CONDITIONAL_BRANCHES is a list of conditional branchs in PIONE language.
      CONDITIONAL_BRANCHES = [:if_branch, :case_branch]

      # +conditional_branch+ matches all conditional branches.
      rule(:conditional_branch) {
        CONDITIONAL_BRANCHES.inject(nil) {|res, elt| res ? res | send(elt) : send(elt)}
      }

      #
      # branch
      #

      # +if_branch+ matches +if+ conditional branches.
      rule(:if_branch) {
        (if_branch_header >> conditional_branch_context.as(:true_context) >> else_context.maybe >> branch_end!).as(:if_branch)
      }

      # +if_branch_header+ matches condition of +if+ branch.
      rule(:if_branch_header) {
        line(keyword_if.as(:declarator) >> space? >> expr!("condition of if branch not found").as(:expr))
      }

      # +else_context+ matches +else+ block.
      rule(:else_context) { line(keyword_else) >> conditional_branch_context.as(:else_context) }

      # +branch_end+ matches conditional branch block end.
      rule(:branch_end) { line(keyword_end) }
      rule(:branch_end!) { branch_end.or_error("conditional branch end not found") }

      # +case_branch+ matches +case+ conditional branches.
      rule(:case_branch) {
        (case_branch_header >> when_contexts >> else_context.maybe >> branch_end!).as(:case_branch)
      }

      # +case_branch_header+ matches +case+ branch beginning.
      rule(:case_branch_header) { line(keyword_case.as(:declarator) >> space? >> expr!.as(:expr)) }

      # +when_context+ matches +when+ contexts.
      rule(:when_context) { when_context_header >> conditional_branch_context.as(:context) }
      rule(:when_contexts) { when_context.repeat.as(:when_contexts) }

      # +when_context_header+ matches +when+ context block.
      rule(:when_context_header) { line(keyword_when >> space? >> expr.as(:expr)) }
    end
  end
end

