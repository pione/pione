module Pione
  class Parser
    # ParserError is raised when the parser finds syntax error.
    class ParserError < Parslet::ParseFailed
      # Creates an error.
      # @param [String] str
      #   target string
      # @param [Array<String>] expected
      #   expected names
      # @param [Parslet::Source] source
      #   parser source
      def initialize(str, expected, source)
        @str = str
        @expected = expected
        @source = source
        super(str)
      end

      # @api private
      def message
        line, column = @source.line_and_column
        expected = @expected.join(", ")
        left = @source.consume(@source.chars_left)
        "%s(expected: %s, line: %s, column: %s):\n%s" % [
          @str, expected, line, column, left
        ]
      end
    end

    # @api private
    class SyntaxErrorAtom < Parslet::Atoms::Base
      def initialize(msg, expected_elements=[])
        @msg = msg
        @expected_elements = expected_elements
      end

      def try(source, context)
        raise ParserError.new(@msg, @expected_elements, source)
      end

      def to_s_inner(prec)
        "SYNTAX_ERROR"
      end
    end

    # SyntaxError provides notification methods for syntax error.
    module SyntaxError
      # Raises syntax error. This method returns a dummy atom and the parser
      # evaluates it as error.
      # @param [String] msg
      #   error message
      # @param [Array<String>] expected_elements
      #   expected name list
      # @return [SyntaxErrorAtom]
      #   dummy atom for parser
      def syntax_error(msg, *expected_elements)
        SyntaxErrorAtom.new(msg, expected_elements)
      end
    end
  end
end
