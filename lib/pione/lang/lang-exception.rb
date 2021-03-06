module Pione
  module Lang
    class LangError < StandardError; end

    # EnvironmentError is raised when the environment is something bad.
    class EnvironmentError < LangError; end

    # StructuralError is raised when there is an unexpected expression in a model
    # structure.
    class StructuralError < LangError
      def initialize(expected, pos)
        @expected = expected
        @pos = pos
      end

      def message
        name = @expected.name
        pos = @pos.format
        "the expression should be %s(%s)" % [name, pos]
      end
    end

    # ContextError is raised when contexts have unacceptable elements or we try
    # to composite different contexts.
    class ContextError < LangError
      def initialize(declaration_or_context, context)
        @obj = declaration_or_context
        @context = context
      end

      def context_type
        case @context
        when ConditionalBranchContext
          "conditional branch context"
        when ParamContext
          "parameter context"
        when RuleConditionContext
          "rule condition contexxt"
        when FlowContext
          "flow context"
        when PackageContext
          "package context"
        when LiteralContext
          "literal context"
        else
          raise ArgumentError.new(self)
        end
      end

      def message
        name = @obj.class.name
        pos = @obj.pos.format
        "%s is not acceptable for %s%s" % [name, context_type, pos]
      end
    end

    # ParamError is raised when undefined parameter is specified.
    class ParamError < LangError
      def initialize(name, package_id)
        @name = name
        @package_id = package_id
      end

      def message
        "parameter %s is not declared in package %s" % [@name, @package_id]
      end
    end

    #
    # declaration errors
    #

    class DeclarationError < LangError
      def initialize(declaration)
        @declaration = declaration
      end
    end

    # ParamDeclarationError is raised when parameter declaration is something
    # bad.
    class ParamDeclarationError < DeclarationError
    end

    #
    # Binding errors
    #

    class BindingError < LangError
      def name
        case @ref
        when Variable
          "variable $%s" % @ref.name
        when RuleExpr
          "rule %s" % @ref.name
        when PackageExpr
          "package &%s" % @ref.name
        end
      end
    end

    # UnboundError is raised when unbound variable, rule, or package was referred.
    class UnboundError < BindingError
      def initialize(ref)
        @ref = ref
      end

      def message
        case @ref
        when Variable, RuleExpr
          "%s in package %s is unbound%s" % [name, @ref.package_id, @ref.pos.format]
        when PackageExpr
          "package &%s is unknown" % @ref.package_id
        end
      end
    end

    # RebindError is raised when we try to rebind some value in variable table,
    # param table, or rule table.
    class RebindError < BindingError
      def initialize(ref)
        @ref = ref
      end

      def message
        "try to rebind %s in package &%s%s" % [name, @ref.package_id, @ref.pos.format]
      end
    end

    # CircularReferenceError is raised when variable or rule reference loop was deteced.
    class CircularReferenceError < BindingError
      def initialize(ref)
        @ref = ref
      end

      def message
        "reference of %s in package &%s made loop%s" % [name, @ref.package_id, @ref.pos.format]
      end
    end

    #
    # Others
    #
    class IndexError < StandardError
      def initialize(index)
        @index = index
      end

      def message
        "index is out of range: %s" % [@index.inspect]
      end
    end

    #
    # expressions
    #

    # LangTypeError represents type mismatch error in PIONE language.
    class LangTypeError < StandardError
      def initialize(obj, type, env)
        @obj = obj
        @type = type
        @env = env
      end

      def message
        args = [
          @type.name,
          @obj.pione_type(env).name,
          @obj.line,
          @obj.column
        ]
        "expected %s, but got %s(line: %s, column: %s)" % args
      end
    end

    # MethodNotFound is an exception class for the case of method missing.
    class MethodNotFound < StandardError
      attr_reader :name
      attr_reader :receiver
      attr_reader :arguments

      # Creates an exception.
      # @param env [Environment]
      #   language environment
      # @param name [String]
      #   method name
      # @param receiver [Callable]
      #   method reciever
      # @param arguments [Array<Callable>]
      #   method arguments
      def initialize(env, name, receiver, arguments)
        @env = env
        @name = name
        @receiver = receiver
        @arguments = arguments
      end

      def message
        rec_type = @receiver.pione_type(@env)
        arg_types = @arguments.map{|arg| arg.pione_type(@env)}.join(" -> ")
        "PIONE method \"%s\" is not found: %s. %s" % [@name, rec_type, arg_types]
      end
    end

    #
    # parser
    #

    # ParserError is raised when the parser finds syntax error.
    class ParserError < Parslet::ParseFailed
      # Creates an error.
      def initialize(str, expected, source)
        @str = str
        @expected = expected
        @source = source
        super(str)
      end

      def message
        line, column = @source.line_and_column
        left = @source.consume(@source.chars_left).str.split("\n").first
        "%s(line: %s, column: %s): %s" % [@str, line, column, left]
      end
    end

  end
end

