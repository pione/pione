module Pione
  module Model
    # TicketExpr is a ticket expression as alternative input or output
    # conditions of rules for sequential process. An object of this class
    # represents a set of ticket conditions.
    #
    # @example Sequencial process of rule A and B by tickets in PIONE flow rule
    #   Rule Main
    #     input '*.in'
    #     output '*.out'
    #   Flow
    #     rule A ==> <T>
    #     <T> ==> rule B
    #   End
    # @example TicketExpr represents a set
    #   TicketExpr.new("T1") + TicketExpr.new("T2") #=> TicketExpr.new(["T1", "T2"])
    class TicketExpr < Element
      class << self
        # Return an emtpy ticket expression. Empty ticket expression has no
        # ticket conditions.
        def empty
          self.new(Set.new)
        end
      end

      # ticket names
      attr_reader :name
      alias :value :name

      # Create a ticket expression with names.
      #
      # @param names [Set, Array]
      #   ticket names
      def initialize(name)
        @name = name
      end

      # Evaluate the object with the variable table.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        self
      end

      # Return true if the value includes variables.
      #
      # @return [Boolean]
      #   true if the value includes variables
      def include_variable?
        false
      end

      # Composite ticket expressions between this and another.
      #
      # @param other [TicketExpr]
      #   another ticket expression
      # @return [TicketExpr]
      #   compositional ticket expression
      def +(other)
        raise ArgumentError.new(other) unless other.kind_of?(TicketExpr)
        self == other ? self : TicketExpr.new(@names + other.names)
      end

      # @api private
      def task_id_string
        "TicketExpr<#{@names}>"
      end

      # @api private
      def textize
        "<%s>" % [@names]
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @name == other.name
      end
      alias :eql? :"=="

      # @api private
      def hash
        @name.hash
      end
    end

    class TicketExprSequence < OrdinalSequence
      set_pione_model_type TypeTicketExpr
      set_element_class TicketExpr
      set_shortname "TSeq"

      def names
        @elements.map do |elt|
          elt.name
        end
      end
    end

    TypeTicketExpr.instance_eval do
      define_pione_method("==>", [TypeRuleExpr], TypeRuleExpr) do |rec, other|
        other.add_input_ticket_expr(rec)
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        rec.textize
      end
    end
  end
end
