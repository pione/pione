module Pione
  module Parser
    # ExprParser is a set of parser atoms for PIONE expressions.
    module ExprParser
      include Parslet
      include SyntaxError
      include CommonParser
      include LiteralParser
      include FeatureExprParser

      # @!attribute [r] expr
      #   +expr+ matches all expressions in PIONE document.
      #   @return [Parslet::Atoms::Entity] +expr+ atom
      #   @example
      #     "abc"[0]
      #   @example
      #     'abc'.as_string
      #   @example
      #     1 + 1
      #   @example
      #     (1 + 1).next
      #   @example
      #     ("abc" + "def")[1]
      #   @example
      #     true
      #   @example
      #     '*.txt'.as_string
      rule(:expr) {
        ( expr_operator_application |
          assignment |
          expr_prepositional_messages.as(:reverse_messages) >> pad? >> expr.as(:receiver) |
          expr_element
        ).as(:expr)
      }


      # @!attribute [r] expr_prepositional_messages
      #   +expr_messages+ matches prepositional messages.
      #   @return [Parslet::Atoms::Entity] +expr_prepositional_messages+ atom
      rule(:expr_prepositional_messages) {
        (pad? >> reverse_message).repeat(1)
      }

      # @!attribute [r] expr_postpositional_messages
      #   +expr_messages+ matches postpositional messages.
      #   @return [Parslet::Atoms::Entity] +expr_post_positional_messages+ atom
      rule(:expr_postpositional_messages) {
        (pad? >> (index | message | parameters.as(:postpositional_parameters))).repeat(1)
      }

      # @!attribute [r] expr_element
      #   +expr_element+ matches simple expressions.
      #   @return [Parslet::Atoms::Entity] +expr_element+ atom
      #   @example
      #     true
      #   @example
      #     (1 + 1)
      #   @example
      #     ("abc".index(1, 1))
      rule(:expr_element) {
        expr_basic_element.as(:receiver) >> expr_postpositional_messages.as(:messages) |
        expr_basic_element
      }

      # @!attribute [r] expr_element
      #   +expr_element+ matches simple expressions.
      #   @return [Parslet::Atoms::Entity] +expr_element+ atom
      #   @example
      #     true
      #   @example
      #     (1 + 1)
      #   @example
      #     ("abc".index(1, 1))
      rule(:expr_basic_element) {
        atomic_expr |
        lparen >> expr >> rparen
      }

      # @!attribute [r] atomic_expr
      #   +expr+ matches atomic expressions.
      #   @return [Parslet::Atoms::Entity] +atomic_expr+ atom
      #   @example
      #     true
      #   @example
      #     false
      #   @example
      #     0.1
      #   @example
      #     1
      #   @example
      #     "abc"
      #   @example
      #     $var
      #   @example
      #     '*.txt'
      #   @example
      #     null
      #   @example
      #     {var: 1}
      #   @example
      #     $abc:test
      #   @example
      #     abc
      rule(:atomic_expr) {
        boolean |
        float |
        integer |
        string |
        ticket |
        data_expr |
        rule_expr |
        feature_expr |
        parameters |
        variable
      }

      # +data_expr+ matches data expressions.
      rule(:data_expr) {
        data_name | keyword_null.as(:data_null)
      }

      # @!attribute [r] rule_expr
      #   +rule_expr+ matches rule expressions.
      #   @return [Parslet::Atoms::Entity] +rule_expr+ atom
      #   @example
      #     &abc:test
      #   @example
      #     :test
      #   @example
      #     test
      rule(:rule_expr) {
        ( package_name.as(:package) >> colon >> rule_name.as(:expr) |
          colon >> rule_name |
          rule_name
        ).as(:rule_expr)
      }

      # @!attribute [r] expr_operator
      #   +expr_operator+ matches expression operators.
      #   @return [Parslet::Atoms::Entity] +expr_operator+ atom
      #   @example
      #     :=, ==, !=, >=, >, <=, <, &&, ||, +, -, *, /, %, or, and
      rule(:expr_operator) {
        equals >> equals >> greater_than |
        equals >> equals |
        exclamation >> equals |
        less_than >> equals |
        less_than |
        greater_than >> greater_than >> greater_than |
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

      # @!attribute [r] expr_operator_application
      #   +expr_operator_application+ matches operator application.
      #   @return [Parslet::Atoms::Entity] +expr_operator_application+ atom
      #   @example
      #     X + X
      rule(:expr_operator_application) {
        ( expr_element.as(:left) >>
          pad? >>
          expr_operator.as(:operator) >>
          pad? >>
          expr.as(:right)
        ).as(:expr_operator_application)
      }

      # @!attribute [r] assignment
      #   +assignment+ matches variable assignment.
      #   @return [Parslet::Atoms::Entity] +assignment+ atom
      #   @example
      #     $X := 1
      rule(:assignment) {
        ( variable.as(:symbol) >>
          space? >>
          colon >> equals >>
          pad? >>
          expr.as(:value)
        ).as(:assignment)
      }

      # @!attribute [r] message
      #   +message+ matches message sending.
      #   @return [Parslet::Atoms::Entity] +message+ atom
      #   @example
      #     # message with no arguments
      #     .as_string
      #   @example
      #     # message with arguments
      #     .params("-w")
      rule(:message) {
        ( dot >>
          identifier.as(:message_name) >>
          message_parameters.maybe
        ).as(:message)
      }

      # @!attribute [r] reverse_message
      #   +message+ matches reverse message sending.
      #   @return [Parslet::Atoms::Entity] +reverse_message+ atom
      #   @example
      #     # message with no arguments
      #     as_string ::
      #   @example
      #     # message with arguments
      #     params("-w") ::
      rule(:reverse_message) {
        ( identifier.as(:message_name) >>
          message_parameters.maybe >>
          pad? >>
          colon >> colon
        ).as(:message)
      }

      # @!attribute [r] message_parameters
      #   +message_parameters+ matches message parameters.
      #   @return [Parslet::Atoms::Entity] +message_parameters+ atom
      #   @example
      #     ("-w")
      #   @example
      #     (true, false)
      rule(:message_parameters) {
        lparen >>
        pad? >>
        message_parameters_elements.maybe.as(:message_parameters) >>
        pad? >>
        rparen
      }

      # @!attribute [r] message_parameters_elements
      #   +message_parameters_elements+ matches message parameters.
      #   @return [Parslet::Atoms::Entity] +message_parameters_elements+ atom
      #   @example
      #     (true)
      #   @example
      #     (true, true, true)
      rule(:message_parameters_elements) {
        expr >> message_parameters_elements_rest.repeat
      }

      # @!attribute [r] message_paramters_elements_rest
      #   +message_parameters_elements+ matches message parameters rest.
      #   @return [Parslet::Atoms::Entity] +message_paramters_elements_rest+ atom
      #   @example
      #     , true
      rule(:message_parameters_elements_rest) {
        pad? >> comma >> pad? >> expr
      }

      #
      # INDEX
      #

      # @!attribute [r] index
      #   +index+ matches object index.
      #   @return [Parslet::Atoms::Entity] +index+ atom
      #   @example
      #     [1]
      #     [1,1]
      #     [1,2,3]
      #     ["a"]
      #     ["a", "b", "c"]
      #   @example
      #     [Var: 1]
      rule(:index) {
        ( lsbracket >>
          pad? >>
          ( index_arguments.as(:index) |
            syntax_error("it should be index arguments", :expr)) >>
          pad? >>
          (rsbracket | syntax_error("it should be index end ']'"))
        )
      }

      # @!attribute [r] index_arguments
      #   +index_arguments+ matches arguments of object index.
      #   @return [Parslet::Atoms::Entity] +index_arguments+ atom
      #   @example
      #     1
      #     1,1
      #     1,2,3
      rule(:index_arguments) {
        expr.repeat(1,1) >> pad? >> index_arguments_rest.repeat
      }

      # @!attribute [r] index_arguments_rest
      #   +index_arguments_rest+ matches tail elements in index expression.
      #   @return [Parslet::Atoms::Entity] +index_arguments_rest+ atom
      #   @example
      #     ,1
      rule(:index_arguments_rest) {
        pad? >>
        comma >>
        pad? >>
        (expr | syntax_error("it should be expr", :expr))
      }
    end
  end
end
