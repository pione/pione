module Pione
  class Parser
    module Expr
      include Parslet
      include SyntaxError
      include Common
      include Literal

      # expr:
      #   1 + 1
      #   (1 + 1).next
      #   true
      #   '*.txt'.as_string
      rule(:expr) {
        ( expr_operator_application |
          expr_element >> message.repeat.as(:messages)
          ).as(:expr)
      }

      # expr_element:
      #   true
      #   (1 + 1)
      #   ("abc".index(1, 1))
      rule(:expr_element) {
        ( atomic_expr.as(:atom) >>
          message.repeat.as(:messages)
          ).as(:atomic_expr) |
        lparen >> expr >> rparen
      }

      # atomic_expr:
      #   true
      #   0.1
      #   1
      #   "abc"
      #   $var
      #   '*.txt'
      #   abc
      rule(:atomic_expr) {
        boolean |
        float |
        integer |
        string |
        variable |
        data_name |
        rule_name
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

      # messages:
      #   .param("-w").sync
      rule(:messages) {
        message.repeat.as(:messages)
      }

      # message:
      #   .params("-w")
      #   .sync
      rule(:message) {
        (dot >>
         identifier.as(:message_name) >>
         message_arguments.maybe
         ).as(:message)
      }

      # message_arguments:
      #   ("-w")
      #   (true, false)
      rule(:message_arguments) {
        lparen >>
        space? >>
        message_arguments_elements.maybe.as(:message_arguments) >>
        space? >>
        rparen
      }

      # message_arguments_elements:
      #   (true)
      #   (true, true, true)
      rule(:message_arguments_elements) {
        expr >> message_arguments_elements_rest.repeat
      }

      # message_arguments_elements_rest:
      #   , true
      rule(:message_arguments_elements_rest) {
        space? >> comma >> space? >> expr
      }
    end
  end
end
