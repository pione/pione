module Pione
  module Parser
    # LiteralParser is a set of parser atom for literal descriptions.
    module LiteralParser
      include Parslet

      # +boolean+ matches +true+ or +false+.
      rule(:boolean) { (keyword_true | keyword_false).as(:boolean) }

      # +string+ matches string.
      #
      # @example
      #   "abc"
      rule(:string) {
        content = (backslash >> any | dquote.absent? >> any).repeat
        dquote >> content.as(:string) >> dquote!
      }

      # +number+ matches positive/negative numbers.
      rule(:number) { match('[+-]').maybe >> digit.repeat(1) }

      # +integer+ matches integer number.
      #
      # @example
      #   123
      # @example
      #   +123
      # @example
      #   -123
      rule(:integer) { number.as(:integer) }

      # +float+ matches float number.
      #
      # @example
      #   1.0
      # @example
      #   +1.0
      # @example
      #   -1.0
      # @example
      #   1.0e100
      # @example
      #   1.0e+100
      # @example
      #   1.0e-100
      rule(:float) {
        (number >> dot >> digit.repeat(1) >> (match('[eE]') >> number).maybe).as(:float)
      }

      # +variable+ matches PIONE variables.
      #
      # @example
      #   $VAR
      # @example
      #   $*
      rule(:variable) { doller >> (asterisk | identifier).as(:variable) }

      # +data_name+ matches data name.
      #
      # @example
      #   'result.txt'
      # @example
      #   '*.txt'
      rule(:data_name) {
        content = (backslash >> any | squote.absent? >> any).repeat
        squote >> content.as(:data_name) >> squote
      }

      # +package_name+ matches package name.
      #
      # @example
      #   &Main
      rule(:package_name) { ampersand >> identifier.repeat(1).as(:package_name) }

      # +rule_name+ matches rule name.
      #
      # @example
      #   Main
      rule(:rule_name) { identifier.as(:rule_name) }

      # +parameters+ matches parameters table.
      #
      # @example
      #   {abc: "a"}
      # @example
      #   {a: 1, b: 2, c: 3}
      rule(:parameters) {
        msg_key = "it should be parameter key"

        content = parameters_elements.maybe.or_error(msg_key, :identifier)
        lbrace >> padded?(content.as(:parameters)) >> rbrace!
      }

      # +parameters_elements+ matches elements of parameters.
      #
      # @example
      #   a: 1, b: 2, c: 3
      rule(:parameters_elements) {
        parameters_element >> parameters_elements_rest.repeat
      }

      # +parameters_element+ matches each element of parameters.
      #
      # @example
      #   a: 1
      rule(:parameters_element) {
        (identifier.as(:key) >> padded?(colon!) >> expr!.as(:value)).as(:parameters_element)
      }

      # +parameters_elements_rest+ matches elements rest of parameters.
      #
      # @example
      #   , a: 1
      rule(:parameters_elements_rest) {
        padded?(comma) >> parameters_element.or_error("it should be parameter key")
      }

      # +ticket+ matches ticket object.
      #
      # @example
      #   <T>
      rule(:ticket) { less_than >> spaced?(identifier.as(:ticket)) >> greater_than }
    end
  end
end
