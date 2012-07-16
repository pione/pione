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
      rule(:expr) {
        ( expr_operator_application |
          expr_element.as(:receiver) >> message.repeat.as(:messages)
          ).as(:expr)
      }

      # expr_element:
      #   true
      #   (1 + 1)
      #   ("abc".index(1, 1))
      rule(:expr_element) {
        ((atomic_expr.as(:receiver) >>
          message.repeat.as(:messages)) |
         lparen >> expr >> rparen
         ).as(:expr)
      }

      # atomic_expr:
      #   true
      #   0.1
      #   1
      #   "abc"
      #   $var
      #   '*.txt'
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
      #   :=, ==, !=, >=, >, <=, <, &&, ||, +, -, *, /, %
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
        percent
      }

      # expr_operator_application:
      #   X + X
      rule(:expr_operator_application) {
        (expr_element.as(:left) >>
         space? >>
         expr_operator.as(:operator) >>
         space? >>
         expr.as(:right)
         ).as(:expr_operator_application)
      }

      # message:
      #   .params("-w")
      #   .sync
      rule(:message) {
        (dot >>
         identifier.as(:message_name) >>
         message_parameters.maybe
         ).as(:message)
      }

      # message_parameters:
      #   ("-w")
      #   (true, false)
      rule(:message_parameters) {
        lparen >>
        space? >>
        message_parameters_elements.maybe.as(:message_parameters) >>
        space? >>
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
        space? >> comma >> space? >> expr
      }
    end
  end
end
