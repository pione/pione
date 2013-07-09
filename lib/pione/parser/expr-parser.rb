module Pione
  module Parser
    # ExprParser is a set of parser atoms for PIONE expressions.
    module ExprParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include FeatureExprParser

      # +expr+ matches all expressions in PIONE document.
      #
      # @example
      #   "abc"[0]
      # @example
      #   'abc'.as_string
      # @example
      #   1 + 1
      # @example
      #   (1 + 1).next
      # @example
      #   ("abc" + "def")[1]
      # @example
      #   true
      # @example
      #   '*.txt'.as_string
      rule(:expr) {
        (expr_operator_application | assignment | reverse_message_sending | expr_element).as(:expr)
      }

      def expr!(msg=nil)
        expr.or_error(msg || "it should be PIONE expression")
      end

      # +reverse_message_sending+ matches reverse message sending.
      rule(:reverse_message_sending) {
        expr_prepositional_messages.as(:reverse_messages) >> pad? >> expr.as(:receiver)
      }

      # +expr_messages+ matches prepositional messages.
      rule(:expr_prepositional_messages) { (pad? >> reverse_message).repeat(1) }

      # +expr_messages+ matches postpositional messages.
      rule(:expr_postpositional_messages) {
        (pad? >> (index | message | parameters.as(:postpositional_parameters))).repeat(1)
      }

      # +expr_element+ matches simple expressions.
      #
      # @example
      #   true
      # @example
      #   (1 + 1)
      # @example
      #   ("abc".index(1, 1))
      rule(:expr_element) {
        expr_basic_element.as(:receiver) >> expr_postpositional_messages.as(:messages) |
        expr_basic_element
      }

      # +expr_element+ matches simple expressions.
      #
      # @example
      #   true
      # @example
      #   (1 + 1)
      # @example
      #   ("abc".index(1, 1))
      rule(:expr_basic_element) { atomic_expr | enclosed_expr }

      # +atomic_expr+ matches atomic expressions.
      #
      # @example
      #   true
      # @example
      #   false
      # @example
      #   0.1
      # @example
      #   1
      # @example
      #   "abc"
      # @example
      #   $var
      # @example
      #   '*.txt'
      # @example
      #   null
      # @example
      #   {var: 1}
      # @example
      #   $abc:test
      # @example
      #   abc
      rule(:atomic_expr) {
        boolean | float | integer | string | ticket | data_expr | rule_expr |
        feature_expr | parameters | variable
      }

      # +enlosed_expr+ matches expressions enclosed by parens.
      rule(:enclosed_expr) { lparen >> expr >> rparen! }

      # +rule_expr+ matches rule expressions.
      #
      # @example
      #   &abc:test
      # @example
      #   :test
      # @example
      #   test
      rule(:rule_expr) {
        ( package_name.as(:package) >> colon >> rule_name.as(:expr) |
          colon >> rule_name |
          rule_name
        ).as(:rule_expr)
      }

      # +expr_operator+ matches expression operators.
      #
      # @example
      #   :=, ==, !=, >=, >, <=, <, &&, ||, +, -, *, /, %, or, and
      # rule(:expr_operator) {
      #   equals >> equals >> greater_than |
      #   equals >> equals |
      #   exclamation >> equals |
      #   less_than >> equals |
      #   less_than |
      #   greater_than >> greater_than >> greater_than |
      #   greater_than >> equals |
      #   greater_than |
      #   ampersand >> ampersand |
      #   vbar >> vbar |
      #   plus |
      #   minus |
      #   asterisk |
      #   slash |
      #   percent |
      #   keyword_or |
      #   keyword_and |
      #   atmark |
      #   vbar
      # }

      rule(:expr_operator_1) {
        plus |
        minus |
        asterisk |
        slash |
        percent |
        atmark |
        (vbar >> vbar).absent? >> vbar |
        keyword_or |
        keyword_and |
        (colon >> colon | colon >> equals).absent? >> colon
      }

      rule(:expr_operator_2) {
        equals >> equals >> equals |
        exclamation >> equals >> equals |
        equals >> equals >> greater_than |
        equals >> equals |
        exclamation >> equals |
        less_than >> equals |
        less_than |
        greater_than >> greater_than >> greater_than |
        greater_than >> equals |
        greater_than |
        ampersand >> ampersand |
        vbar >> vbar
      }

      # +expr_operator_application+ matches operator application.
      #
      # @example
      #   X + X
      rule(:expr_operator_application) {
        expr_operator_application_2 |
        expr_operator_application_1
      }

      rule(:expr_operator_application_1) {
        ( expr_element.as(:left) >>
          padded?(expr_operator_1.as(:operator)) >>
          ((expr_operator_application_1 | expr_element).as(:right) |
            syntax_error("right hand side of the operator application should be expr", [:expr]))
        ).as(:expr_operator_application)
      }

      rule(:expr_operator_application_2) {
        ((expr_operator_application_1 | expr_element).as(:left) >>
          padded?(expr_operator_2.as(:operator)) >>
          expr!("right hand side of the operator application should be expr").as(:right)
        ).as(:expr_operator_application)
      }

      # +assignment+ matches variable assignment.
      #
      # @example
      #   $X := 1
      rule(:assignment) {
        (variable.as(:symbol) >> space? >> colon_eq >> pad? >> expr!.as(:value)).as(:assignment)
      }

      # +message+ matches message sending.
      #
      # @example message with no arguments
      #   .as_string
      # @example message with arguments
      #   .params("-w")
      rule(:message) {
        (dot >> identifier.as(:message_name) >> message_parameters.maybe).as(:message)
      }

      # +message+ matches reverse message sending.
      #
      # @example message with no arguments
      #   as_string ::
      # @example message with arguments
      #   params("-w") ::
      rule(:reverse_message) {
        (identifier.as(:message_name) >> message_parameters.maybe >> pad? >> colon_colon).as(:message)
      }

      # +message_parameters+ matches message parameters.
      #
      # @example
      #   ("-w")
      # @example
      #   (true, false)
      rule(:message_parameters) {
        lparen >> padded?(message_parameters_elements.maybe.as(:message_parameters)) >> rparen!
      }

      # +message_parameters_elements+ matches message parameters.
      #
      # @example
      #   true
      # @example
      #   true, true, true
      rule(:message_parameters_elements) { expr >> (padded?(comma) >> expr!).repeat }

      #
      # INDEX
      #

      # +index+ matches object index.
      #
      # @example
      #   [1]
      #   [1,1]
      #   [1,2,3]
      #   ["a"]
      #   ["a", "b", "c"]
      # @example
      #   [Var: 1]
      rule(:index) { lsbracket >> padded?(index_arguments!.as(:index)) >> rsbracket! }

      # +index_arguments+ matches arguments of object index.
      #
      # @example
      #   1
      #   1, 1
      #   1, 2, 3
      rule(:index_arguments) { expr.repeat(1,1) >> (padded?(comma) >> expr!).repeat }
      rule(:index_arguments!) { index_arguments.or_error("it should be index arguments") }
    end
  end
end
