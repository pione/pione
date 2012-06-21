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
        "#{@str} #{cause}(expected: #{@expected.join(", ")}, #{@source.pos}"
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
      def syntax_error(msg, expect_elements)
        # raise ParserError.new(msg, expect_elements)
        SyntaxErrorAtom.new(msg)
      end
    end
  end
end
