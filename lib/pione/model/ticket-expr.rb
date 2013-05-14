module Pione
  module Model
    # TicketExpr is a ticket expression as alternative input or output
    # conditions of rules for serial processing.
    #
    # @example Serial process of rule A and B by tickets in PIONE flow rule
    #   Rule Main
    #     input '*.in'
    #     output '*.out'
    #   Flow
    #     rule A ==> <T>
    #     <T> ==> rule B
    #   End
    class TicketExpr < Element
      # ticket name
      attr_reader :name

      # @param name [String]
      #   ticket name
      def initialize(name)
        @name = name
      end

      def eval(vtable)
        self
      end

      def include_variable?
        false
      end

      def task_id_string
        "TicketExpr<#{@names}>"
      end

      def textize
        "<%s>" % [@names]
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        @name == other.name
      end
      alias :eql? :"=="

      def hash
        @name.hash
      end
    end

    class TicketExprSequence < OrdinalSequence
      set_pione_model_type TypeTicketExpr
      set_element_class TicketExpr
      set_shortname "TSeq"

      # Get ticket names of all elements in the sequence.
      #
      # @return [Array<String>]
      #   ticket names
      def names
        @elements.map {|elt| elt.name}
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
