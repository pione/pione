module Pione
  module Model
    # PackageExpr is an expression of PIONE package.
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
    end

    class PackageExprSequence < Sequence
      set_pione_model_type TypePackageExpr
      set_element_class PackageExpr
    end

    TypePackageExpr.instance_eval do
      define_pione_method("bin", [], TypeString) do |vtable, rec|
        base = Location[vtable.get(Variable.new("__BASE__")).value]
        bin = base + "package" + rec.elements.first.name + "bin"
        working_directory = Location[vtable.get(Variable.new("__WORKING_DIRECTORY__")).first.value]
        bin.entries.each do |entry|
          path = working_directory + "bin" + entry.basename
          unless path.exist?
            entry.copy(working_directory + "bin" + entry.basename)
          end
        end
        PioneString.new((working_directory + "bin").path).to_seq
      end
    end
  end
end
