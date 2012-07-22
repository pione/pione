module Pione
  class Parser
    module Literal
      include Parslet
      include Common

      # boolean
      rule(:boolean) {
        (keyword_true | keyword_false).as(:boolean)
      }

      # string
      rule(:string) {
        dquote >>
        (backslash >> any | dquote.absent? >> any).repeat.as(:string) >>
        dquote
      }

      # integer
      rule(:integer) {
        ( match('[+-]').maybe >>
          digit.repeat(1)
          ).as(:integer)
      }

      # float
      rule(:float) {
        ( match('[+-]').maybe >>
          digit.repeat(1) >>
          dot >>
          digit.repeat(1) >>
          (match('[eE]') >> digit.repeat(1)).maybe
          ).as(:float)
      }

      # variable
      rule(:variable) {
        doller >>
        identifier.as(:variable)
      }

      # data_name
      rule(:data_name) {
        squote >>
        (backslash >> any | squote.absent? >> any).repeat.as(:data_name) >>
        squote
      }

      # package_name
      rule(:package_name) {
        ampersand >>
        identifier.repeat(1).as(:package_name)
      }

      # rule_name
      rule(:rule_name) {
        identifier.as(:rule_name)
      }

      # parameters is a part of literal syntax but defined in Expr module
      # because it includes expr.
    end
  end
end
