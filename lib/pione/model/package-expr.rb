module Pione
  module Model
    # PackageExpr is a PIONE model class for rule package.
    class PackageExpr < Element
      attr_reader :name

      # Create a package with name.
      #
      # @param name [String]
      #   package name
      def initialize(name)
        @name = name
        super()
      end

      # @api private
      def task_id_string
        "PackageExpr<#{@name}>"
      end

      # @api private
      def textize
        "package-expr(\"%s\")" % [@name]
      end

      # Return a rule path.
      #
      # @param other [RuleExpr]
      #   rule expression
      # @return [String]
      #   rule path string
      def +(other)
        raise ArgumentError.new(other) unless other.kind_of?(RuleExpr)
        "#{@name}:#{other.name}"
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @name == other.name
      end

      alias :eql? :"=="

      # @api private
      def hash
        @value.hash
      end
    end

    class PackageExprSequence < Sequence
      set_pione_model_type TypePackageExpr
      set_element_class PackageExpr
    end
  end
end
