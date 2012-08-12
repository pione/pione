module Pione
  class Parser
    module Literal
      include Parslet

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

      # parameters
      #   {abc: "a"}
      #   {a: 1, b: 2, c: 3}
      rule(:parameters) {
        lbrace >>
        pad? >>
        ( parameters_elements.maybe.as(:parameters) |
          syntax_error("it should be parameter key", :identifier)
        ) >>
        pad? >>
        rbrace
      }

      # parameters_elements
      #   a: 1, b: 2, c: 3
      rule(:parameters_elements) {
        parameters_element >> parameters_elements_rest.repeat
      }

      # parameters_element
      #   a: 1
      #   b: 2
      #   c: 3
      rule(:parameters_element) {
        ( identifier.as(:key) >>
          pad? >>
          colon >>
          pad? >>
          ( expr.as(:value) |
            syntax_error("it should be parameter value", :expr)
          )
        ).as(:parameters_element)
      }

      # parameters_elements_rest
      #   , a: 1
      rule(:parameters_elements_rest) {
        pad? >>
        comma >>
        pad? >>
        ( parameters_element |
          syntax_error("it should be parameter key", :identifier)
        )
      }
    end
  end
end
