module TestUtil
  module Lang
    class Reader
      @parser = {}

      # cache for parser and transformer
      class << self
        def parser(name)
          @parser[name] ||= Pione::Lang::DocumentParser.new.send(name)
        end

        def transformer
          @transformer ||= Pione::Lang::DocumentTransformer.new
        end
      end

      forward! :class, :parser, :transformer

      def initialize(string, parser_name, opts={})
        @string = string
        @parser_name = parser_name
        @opts = {package_name: "Test", filename: "Test.pione"}.merge(opts)
      end

      def read
        parsed = parser(@parser_name).parse(@string)
        opts = {package_name: @opts[:package_name], filename: @opts[:filename]}
        transformer.apply(parsed, opts)
      end
    end

    class << self
      # Read PIONE language and return the result.
      def read(string, parser_name, opts={})
        Reader.new(string, parser_name, opts).read
      end

      # Read a declaration.
      def declaration(string, opts={})
        read(string, :declaration, opts)
      end

      def declaration!(env, string, opts={})
        declaration(string, opts).eval(env)
      end

      # Read a conditional branch.
      def conditional_branch(string, opts={})
        read(string, :conditional_branch, opts)
      end

      # Read a structural context.
      def context(string, opts={})
        read(string, :structural_context, opts)
      end

      def context!(env, string, opts={})
        context(string, opts).eval!(env)
      end

      # Read a package context.
      def package_context(string, opts={})
        read(string, :package_context, opts)
      end

      # Read and evaluate a package context.
      def package_context!(env, string, opts={})
        package_context(string, opts).eval!(env)
      end

      # Read a rule condition context.
      def rule_condition_context(string, opts={})
        read(string, :rule_condition_context, opts)
      end

      # Read and evaluate a rule condition context.
      def rule_condition_context!(env, string, opts={})
        rule_condition_context(string, opts).eval!(env)
      end

      # Read a conditional branch context.
      def conditional_branch_context(string, opts={})
        read(string, :conditional_branch_context, opts)
      end

      # Read and evaluate a rule condition context.
      def conditional_branch_context!(env, string, opts={})
        conditional_branch_context(string, opts).eval!(env)
      end

      # Read an expression.
      def expr(string, opts={})
        read(string, :expr, opts)
      end

      # Read and evaluate an expression.
      def expr!(env, string, opts={})
        expr(string, opts).eval!(env)
      end

      # Read a feature expression.
      def feature_expr(string, opts={})
        read(string, :feature_expr, opts)
      end

      # Read and evaluate a feature expression.
      def feature_expr!(string, opts={})
        feature_expr(string, opts).eval(env)
      end

      # Build an environment and update it with the string as structural context.
      def env(string=nil)
        _env = Pione::Lang::Environment.new.setup_new_package("Test")
        context(string).eval(_env) if string
        _env
      end
    end
  end
end
