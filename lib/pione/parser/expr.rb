module Pione
  class Parser
    module Expr
      include Parslet
      include SyntaxError
      include Common
      include Literal
      include FeatureExpr

      # expr:
      #   1 + 1
      #   (1 + 1).next
      #   true
      #   '*.txt'.as_string
      #   abc[1]
      rule(:expr) {
        ( expr_operator_application |
          (expr_element.as(:receiver) >>
            (index | message).repeat(1).as(:messages)) |
          expr_element
        ).as(:expr)
      }

      # expr_element:
      #   true
      #   (1 + 1)
      #   ("abc".index(1, 1))
      rule(:expr_element) {
        ( (atomic_expr.as(:receiver) >> indexes) |
          (atomic_expr.as(:receiver) >> messages) |
          atomic_expr |
          lparen >> expr >> rparen
        )
      }

      # atomic_expr:
      #   true
      #   0.1
      #   1
      #   "abc"
      #   $var
      #   '*.txt'
      #   {var: 1}
      #   $abc:test
      #   abc
      rule(:atomic_expr) {
        boolean |
        float |
        integer |
        string |
        data_name |
        rule_expr |
        feature_expr |
        parameters |
        variable
      }

      # rule_expr:
      #   &abc:test
      #   :test
      #   test
      rule(:rule_expr) {
        ( package_name.as(:package) >> colon >> rule_name.as(:expr) |
          colon >> rule_name |
          rule_name
        ).as(:rule_expr)
      }

      # expr_operator:
      #   :=, ==, !=, >=, >, <=, <, &&, ||, +, -, *, /, %, or, and
      rule(:expr_operator) {
        equals >> equals |
        exclamation >> equals |
        less_than >> equals |
        less_than |
        greater_than >> equals |
        greater_than |
        ampersand >> ampersand |
        vbar >> vbar |
        plus |
        minus |
        asterisk |
        slash |
        percent |
        keyword_or |
        keyword_and
      }

      # expr_operator_application:
      #   X + X
      rule(:expr_operator_application) {
        ( expr_element.as(:left) >>
          pad? >>
          expr_operator.as(:operator) >>
          pad? >>
          expr.as(:right)
        ).as(:expr_operator_application)
      }

      # messages:
      #   .params("-w").sync
      rule(:messages) {
        message.repeat(1).as(:messages)
      }

      # message:
      #   .params("-w")
      #   .sync
      rule(:message) {
        ( dot >>
          identifier.as(:message_name) >>
          message_parameters.maybe
        ).as(:message)
      }

      # message_parameters:
      #   ("-w")
      #   (true, false)
      rule(:message_parameters) {
        lparen >>
        pad? >>
        message_parameters_elements.maybe.as(:message_parameters) >>
        pad? >>
        rparen
      }

      # message_parameters_elements:
      #   (true)
      #   (true, true, true)
      rule(:message_parameters_elements) {
        expr >> message_parameters_elements_rest.repeat
      }

      # message_paramters_elements_rest:
      #   , true
      rule(:message_parameters_elements_rest) {
        pad? >> comma >> pad? >> expr
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

      # indexes:
      #   [1][2][3]
      rule(:indexes) {
        index.repeat(1).as(:indexes)
      }

      # index:
      #   [1]
      #   [1,1]
      #   [1,2,3]
      rule(:index) {
        ( lsbracket >>
          space? >>
          ( index_arguments.as(:index) |
            syntax_error("it should be index arguments", :expr)) >>
          space? >>
          rsbracket
        )
      }

      # index_arguments:
      #   1
      #   1,1
      #   1,2,3
      rule(:index_arguments) {
        expr.repeat(1,1) >> space? >> index_arguments_rest.repeat
      }

      # index_arguments_rest:
      #  ,1
      rule(:index_arguments_rest) {
        space? >>
        comma >>
        space? >>
        ( expr |
          syntax_error("it should be expr", :expr)
        )
      }
    end
  end
end
