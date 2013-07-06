module Pione
  module Parser
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
      def initialize(msg, expected_elements=[], ignore_error)
        @msg = msg
        @expected_elements = expected_elements
        @ignore_error = ignore_error
      end

      def try(source, context, _)
        raise ParserError.new(@msg, @expected_elements, source)
      end

      def to_s_inner(prec)
        "SYNTAX_ERROR"
      end
    end

    class IgnoreErrorAtom < Parslet::Atoms::Base
      def initialize(atom)
        @atom = atom
      end

      def try(source, context)
        begin
          @atom.apply(source, context)
        rescue ParserError
          context.err(self, source, "", [])
        end
      end

      def to_s_inner(prec)
        "IGNORE_ERROR"
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
        SyntaxErrorAtom.new(msg, expected_elements, $ignore_error)
      end

      def should(atom, msg, *expected_elements)
        atom | syntax_error(msg, *expected_elements)
      end

      def ignore_error(&b)
        res = yield
        return IgnoreErrorAtom.new(res)
      end
    end

    class IgnoreAtom < Parslet::Atoms::Base
      def initialize(atom)
        @atom = atom
      end

      def try(source, context, consume_all)
        success, _ = result = @atom.try(source, context, consume_all)
        return sucess ? succ(nil) : result
      end

      def to_s_inner(prec)
        "IGNORE"
      end
    end

    module Ignore
      def ignore
        IgnoreAtom.new(self)
      end
    end

    class ExceptionAtom < Parslet::Atoms::Base
      def initialize(atom, exception)
        @atom = atom
        @exception = exception
      end

      def try(source, context)
        success, value = result = @atom.apply(source, context)
        if success
          esuccess, _ = @exception.apply(source, context)
          p @exception
          p source
          p esuccess
          if esuccess
            return result
          end
        end
        return result
      end

      def to_s_inner(prec)
        "EXCEPTION"
      end
    end

    module Exception
      def except(exception)
        ExceptionAtom.new(self, exception)
      end
    end
  end
end

class Parslet::Atoms::Base
  include Pione::Parser::Ignore
  include Pione::Parser::Exception

  def or_error(msg, *expected_elements)
    self | SyntaxErrorAtom.new(msg, expected_elements, $ignore_error)
  end
end
