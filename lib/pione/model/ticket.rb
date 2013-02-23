module Pione
  module Model
    # PioneString is a string value in PIONE system.
    class Ticket < BasicModel
      set_pione_model_type TypeTicket
      attr_reader :name

      # Creates a ticket with the name.
      # @param [String] name
      #   ticket name
      def initialize(name)
        raise ArgumentError.new(name) unless name.kind_of?(String)
        @name = name
        super()
      end

      # Evaluates the object with the variable table.
      # @param [VariableTable] vtable
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        self
      end

      # Returns true if the value includes variables.
      # @return [Boolean]
      #   true if the value includes variables
      def include_variable?
        false
      end

      # @api private
      def task_id_string
        "Ticket<#{@name}>"
      end

      # @api private
      def textize
        "<%s>" % [@name]
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

    TypeTicket.instance_eval do
      define_pione_method("==", [TypeTicket], TypeBoolean) do |rec, other|
        PioneBoolean.new(rec.name == other.name)
      end

      define_pione_method("!=", [TypeTicket], TypeBoolean) do |rec, other|
        PioneBoolean.not(rec.call_pione_method("==", other))
      end

      define_pione_method("+", [TypeTicket], TypeList.new(TypeTicket)) do |rec, other|
        PioneList.new(rec, other)
      end

      define_pione_method("as_string", [], TypeString) do |rec|
        rec.textize
      end
    end
  end
end
