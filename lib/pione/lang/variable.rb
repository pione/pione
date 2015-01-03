module Pione
  module Lang
    # Variable is a model for variable name objects that have name string and
    # package id. We use this for getting its value from variable table in the
    # environment.
    #
    # @note Be careful variable are not treated as a sequence, because sequence
    #   is a concept of elements joined by sequencial operators and the
    #   receivers should be evaluated.
    class Variable < Expr
      member :name
      member :package_id

      def pione_type(env)
        env.variable_get(self).pione_type(env)
      end

      # Get the value from variable table in the environment.
      def eval(env)
        env.variable_get(self)
      end

      def eval!(env)
        eval(env).eval!(env)
      end

      def textize
        ("$%s" % name) + (package_id ? "@%s" % package_id : "")
      end

      # Compare with other variable.
      def <=>(other)
        raise ArgumentError.new(other) unless other.kind_of?(self.class)
        name <=> other.name
      end
    end
  end
end
