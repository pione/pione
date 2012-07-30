module Pione
  class Parser
    class ParserError < Parslet::ParseFailed
      def initialize(str, expected, source, context)
        @str = str
        @expected = expected
        @source = source
        super(str)
      end

      def message
        line, column = @source.line_and_column
        expected = @expected.join(", ")
        left = @source.consume(@source.chars_left)
        "%s(expected: %s, line: %s, column: %s):\n%s" % [
          @str, expected, line, column, left
        ]
      end
    end

    class SyntaxErrorAtom < Parslet::Atoms::Base
      def initialize(msg, expected_elements=[])
        @msg = msg
        @expected_elements = expected_elements
      end

      def try(source, context)
        raise ParserError.new(@msg, @expected_elements, source, context)
      end

      def to_s_inner(prec)
        "SYNTAX_ERROR"
      end
    end

    module SyntaxError
      # Shortcut for creating dummy atom.
      def syntax_error(msg, *expect_elements)
        SyntaxErrorAtom.new(msg, expect_elements)
      end
    end
  end
end
