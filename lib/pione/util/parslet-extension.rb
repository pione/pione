module Pione
  module Util
    # SyntaxErrorAtom is a special parslet atom for +on_error+ helper method.
    class SyntaxErrorAtom < Parslet::Atoms::Base
      def initialize(msg, expected_elements=[], ignore_error)
        @msg = msg
        @expected_elements = expected_elements
        @ignore_error = ignore_error
      end

      # Raise a +ParserError+ when this atom is touched.
      def try(source, context, _)
        raise Lang::ParserError.new(@msg, @expected_elements, source)
      end

      def to_s_inner(prec)
        "SYNTAX_ERROR"
      end
    end

    # IgnoreErrorAtom is a parslet atom for +except+ helper method.
    class IgnoreErrorAtom < Parslet::Atoms::Base
      def initialize(atom)
        @atom = atom
      end

      def try(source, context)
        begin
          @atom.apply(source, context)
        rescue Lang::ParserError
          context.err(self, source, "", [])
        end
      end

      def to_s_inner(prec)
        "IGNORE_ERROR"
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

    class ExceptionAtom < Parslet::Atoms::Base
      def initialize(atom, exception)
        @atom = atom
        @exception = exception
      end

      def try(source, context)
        success, value = result = @atom.apply(source, context)
        if success
          esuccess, _ = @exception.apply(source, context)
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

    # ParsletParserExtension provides parser helper methods.
    module ParsletParserExtension
      def ignore
        IgnoreAtom.new(self)
      end

      def except(exception)
        ExceptionAtom.new(self, exception)
      end

      # Create a special atom that raises +ParserError+ when it is tried.
      def or_error(msg, *expected_elements)
        self | SyntaxErrorAtom.new(msg, expected_elements, $ignore_error)
      end

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

    # +ParsletTransformerModule+ enables parslet's transforms to be defined by
    # multiple modules.
    module ParsletTransformerModule
      class << self
        # @api private
        def included(mod)
          singleton = class << mod; self; end
          create_pair_by(Parslet, Parslet::Transform).each do |name, orig|
            singleton.__send__(:define_method, name) do |*args, &b|
              orig.__send__(name, *args, &b)
            end
          end

          class << mod
            def included(klass)
              name = :@__transform_rules
              klass_rules = klass.instance_variable_get(name)
              klass_rules = klass_rules ? klass_rules + rules : rules
              klass.instance_variable_set(name, klass_rules)
            end
          end
        end

        private

        # Create module and the methods pair by modules.
        #
        # @api private
        def create_pair_by(*mods)
          mods.inject([]) do |list, mod|
            list + (mod.methods.sort - Object.methods.sort).map{|m| [m, mod]}
          end
        end
      end
    end
  end
end

class Parslet::Atoms::Base
  include Pione::Util::ParsletParserExtension
end
