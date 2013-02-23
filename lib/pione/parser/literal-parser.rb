module Pione
  module Parser
    # LiteralParser is a set of parser atom for literal descriptions.
    module LiteralParser
      include Parslet

      # @!attribute [r] boolean
      #   +boolean+ matches +true+ or +false+.
      #   @return [Parslet::Atoms::Entity] +boolean+ atom
      #   @example
      #     true
      #   @example
      #     false
      rule(:boolean) {
        (keyword_true | keyword_false).as(:boolean)
      }

      # @!attribute [r] string
      #   +string+ matches string.
      #   @return [Parslet::Atoms::Entity] +string+ atom
      #   @example
      #     "abc"
      rule(:string) {
        dquote >>
        (backslash >> any | dquote.absent? >> any).repeat.as(:string) >>
        (dquote | syntax_error("It should be double quotation.", :dquote))
      }

      # @!attribute [r] integer
      #   +integer+ matches integer number.
      #   @return [Parslet::Atoms::Entity] +integer+ atom
      #   @example
      #     123
      #   @example
      #     +123
      #   @example
      #     -123
      rule(:integer) {
        ( match('[+-]').maybe >>
          digit.repeat(1)
        ).as(:integer)
      }

      # @!attribute [r] float
      #   +float+ matches float number.
      #   @return [Parslet::Atoms::Entity] +float+ atom
      #   @example
      #     1.0
      #   @example
      #     +1.0
      #   @example
      #     -1.0
      #   @example
      #     1.0e100
      #   @example
      #     1.0e+100
      #   @example
      #     1.0e-100
      rule(:float) {
        ( match('[+-]').maybe >>
          digit.repeat(1) >>
          dot >>
          digit.repeat(1) >>
          (match('[eE]') >> match('[+-]').maybe >> digit.repeat(1)).maybe
        ).as(:float)
      }

      # @!attribute [r] float
      #   +float+ matches float number.
      #   @return [Parslet::Atoms::Entity] +float+ atom
      #   @example
      #     $VAR
      #   @example
      #     $*
      rule(:variable) {
        doller >>
        (asterisk | identifier).as(:variable)
      }

      # @!attribute [r] data_name
      #   +data_name+ matches data name.
      #   @return [Parslet::Atoms::Entity] +data_name+ atom
      #   @example
      #     'result.txt'
      #   @example
      #     '*.txt'
      rule(:data_name) {
        squote >>
        (backslash >> any | squote.absent? >> any).repeat.as(:data_name) >>
        squote
      }

      # @!attribute [r] package_name
      #   +package_name+ matches package name.
      #   @return [Parslet::Atoms::Entity] +package_name+ atom
      #   @example
      #     &Main
      rule(:package_name) {
        ampersand >>
        identifier.repeat(1).as(:package_name)
      }

      # @!attribute [r] rule_name
      #   +rule_name+ matches rule name.
      #   @return [Parslet::Atoms::Entity] +rule_name+ atom
      #   @example
      #     Main
      rule(:rule_name) {
        identifier.as(:rule_name)
      }

      # @!attribute [r] parameters
      #   +parameters+ matches parameters table.
      #   @return [Parslet::Atoms::Entity] +parameters+ atom
      #   @example
      #     {abc: "a"}
      #   @example
      #     {a: 1, b: 2, c: 3}
      rule(:parameters) {
        lbrace >>
        ( pad? >>
          ( parameters_elements.maybe.as(:parameters) |
            syntax_error("it should be parameter key", :identifier)
          ) >>
          pad? >>
          (rbrace | syntax_error("it should be parameters end.", :parameters_end))
        )
      }

      # @!attribute [r] parameters_elements
      #   +parameters_elements+ matches elements of parameters.
      #   @return [Parslet::Atoms::Entity] +parameters_elements+ atom
      #   @example
      #     a: 1, b: 2, c: 3
      rule(:parameters_elements) {
        ( parameters_element >>
          parameters_elements_rest.repeat
        )
      }

      # @api private
      MSG_MISSING_COLON =
        "Parameter elements should be 'key:value' form, but colon is missing."

      # @api private
      MSG_MISSING_VALUE =
        "it should be parameter value."

      # @!attribute [r] parameters_element
      #   +parameters_element+ matches each element of parameters.
      #   @return [Parslet::Atoms::Entity] +parameters_element+ atom
      #   @example
      #     a: 1
      #   @example
      #     b: 2
      #   @example
      #     c: 3
      rule(:parameters_element) {
        ( identifier.as(:key) >>
          pad? >>
          (colon | syntax_error(MSG_MISSING_COLON, :colon)) >>
          pad? >>
          (expr.as(:value) | syntax_error(MSG_MISSING_VALUE, :expr))
        ).as(:parameters_element)
      }

      # @!attribute [r] parameters_elements_rest
      #   +parameters_elements_rest+ matches elements rest of parameters.
      #   @return [Parslet::Atoms::Entity] +parameters_elements_rest+ atom
      #   @example
      #     , a: 1
      rule(:parameters_elements_rest) {
        pad? >>
        comma >>
        pad? >>
        ( parameters_element |
          syntax_error("it should be parameter key", :identifier)
        )
      }

      # @!attribute [r] ticket
      # +ticket+ matches ticket object.
      #
      # @return [Parslet::Atoms::Entity] +ticket+ atom
      # @example
      #   &Main
      rule(:ticket) {
        less_than >>
        space? >>
        identifier.as(:ticket) >>
        space? >>
        greater_than
      }
    end
  end
end
