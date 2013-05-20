module Pione
  module Model
    # Rule representation in the flow element context.
    class RuleExpr < Callable
      include SimpleIdentity

      set_pione_model_type TypeRuleExpr

      # @return [PackageExpr]
      #   package expression
      attr_reader :package_expr

      # @return [String]
      #   rule name
      attr_reader :name

      # @return [Hash]
      #   attributes of the rule expression
      attr_reader :attributes

      forward_as_key! :@attributes, :params, :input_ticket_expr, :output_ticket_expr

      # Create a rule expression.
      #
      # @param package_expr [PackageExpr]
      #   package expression
      # @param name [String]
      #   rule name
      # @param attributes [Hash]
      #   attributes of the expression
      # @option attributes [Model::Parameters] :params
      #   rule parameters
      # @option attributes [Model::TicketExpr] :input_ticket_expr
      #   input ticket condition
      # @option attributes [Model::TicketExpr] :output_ticket_expr
      #   output ticket condition
      def initialize(package_expr, name, attributes={})
        @package_expr = package_expr
        @name = name
        @attributes = {}
        @attributes[:params] = attributes[:params] || Model::Parameters.empty
        @attributes[:input_ticket_expr] = attributes[:input_ticket_expr] || Model::TicketExprSequence.empty
        @attributes[:output_ticket_expr] = attributes[:output_ticket_expr] || Model::TicketExprSequence.empty
        super()
      end

      # Return rule path form.
      #
      # @return [String]
      #   rule path string
      def path
        "&%s:%s" % [@package_expr.name, @name]
      end

      # FIXME
      def rule_path
        raise UnboundVariableError.new(self) if @package_expr.include_variable?
        "&%s:%s" % [@package_expr.name, @name]
      end

      # @api private
      def task_id_string
        "RuleExpr<%s,#{@name}>" % [@package_expr.task_id_string]
      end

      # @api private
      def textize
        "rule_expr(%s,\"%s\")" % [@package_expr.textize, @name]
      end

      # Create a new rule expression with adding the ticket expression as input
      # condition.
      #
      # @param ticket_expr [TicketExpr]
      #   ticket expression as additional input condition
      # @return [RuleExpr]
      #   new rule expression
      def add_input_ticket_expr(ticket_expr)
        new_attributes = @attributes.merge(input_ticket_expr: @attributes[:input_ticket_expr].concat(ticket_expr))
        return self.class.new(@package_expr, @name, new_attributes)
      end

      # Create a new rule expression with adding the ticket expression as output
      # condition.
      #
      # @param ticket_expr [TicketExpr]
      #   ticket expression as additional output condition
      # @return [RuleExpr]
      #   new rule expression
      def add_output_ticket_expr(ticket_expr)
        new_attributes = @attributes.merge(output_ticket_expr: @attributes[:output_ticket_expr].concat(ticket_expr))
        return self.class.new(@package_expr, @name, new_attributes)
      end

      # Sets a package name and returns a new expression.
      #
      # @param package_expr [PackageExpr]
      #   package expression
      # @return [RuleExpr]
      #   new rule expression with the package name
      def set_package_expr(package_expr)
        return self.class.new(package_expr, @name, @attributes)
      end

      # Set parameters and returns a new expression.
      #
      # @param params [Parameters]
      #   parameters
      # @return [RuleExpr]
      #   new rule expression with the parameters
      def set_params(params)
        new_attributes = @attributes.merge(params: params)
        return self.class.new(@package_expr, @name, new_attributes)
      end

      # Evaluate the object with the variable table.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [RuleExpr]
      #   evaluation result
      def eval(vtable)
        new_attributes = Hash[@attributes.map{|key, val| [key, val.eval(vtable)]}]
        return self.class.new(@package_expr.eval(vtable), @name, new_attributes)
      end

      # Return true if the package expression or parameters include variables.
      #
      # @return [Boolean]
      #   true if the package expression or parameters include variables
      def include_variable?
        @package_expr.include_variable? or @attributes.values.any?{|val| val.include_variable?}
      end

      # Return a set that contains self as a single element.
      #
      # @return [Set<RuleExpr>]
      #   a set that contains self
      def to_set
        Set.new([self])
      end
    end

    class CompositionalRuleExpr < RuleExpr
      # Create a new compositional rule expression. This consists from left and
      # right child expressions.
      #
      # @param left [RuleExpr]
      #   left expression
      # @param right [RuleExpr]
      #   right expression
      def initialize(left, right)
        @left = left
        @right = right
      end

      # Create a new compositioanl rule expression with adding the ticket
      # expression as input condition of left expression.
      #
      # @param ticket_expr [TicketExpr]
      #   ticket expression as additional input condition
      # @return [CompositionalRuleExpr]
      #   new rule expression
      def add_input_ticket_expr(ticket_expr)
        return self.class.new(@left.add_input_ticket_expr(ticket_expr), @right)
      end

      # Create a new compositional rule expression with adding the ticket
      # expression as output condition of right expression.
      #
      # @param ticket_expr [TicketExpr]
      #   ticket expression as additional output condition
      # @return [CompositionalRuleExpr]
      #   new rule expression
      def add_output_ticket_expr(ticket_expr)
        return self.class.new(@left, @right.add_output_ticket_expr(ticket_expr))
      end

      # Evaluate left and right expressions with the variable table.
      #
      # @param [VariableTable] vtable
      #   variable table for evaluation
      # @return [CompositionalRuleExpr]
      #   evaluation result
      def eval(vtable)
        return self.class.new(@left.eval(vtable), @right.eval(vtable))
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        return to_set == other.to_set
      end
      alias :eql? :"=="

      # @api private
      def hash
        @left.hash + @right.hash
      end

      # Return a set that contains all rule expressions of left and right.
      #
      # @return [Set<RuleExpr>]
      #   a set that contains all rule expressions of left and right
      def to_set
        @left.to_set + @right.to_set
      end
    end

    class RuleExprSequence < Sequence
      set_pione_model_type TypeRuleExpr
    end

    TypeRuleExpr.instance_eval do
      define_pione_method("==", [TypeRuleExpr], TypeBoolean) do |vtable, rec, other|
        PioneBoolean.new(rec == other).to_seq
      end

      define_pione_method("params", [TypeParameters], TypeRuleExpr) do |vtable, rec, params|
        rec.set_params(params)
      end

      define_pione_method("as_string", [], TypeString) do |vtable, rec|
        PioneString.new(rec.name).to_seq
      end

      define_pione_method("==>", [TypeTicketExpr], TypeRuleExpr) do |vtable, rec, ticket_expr|
        rec.add_output_ticket_expr(ticket_expr)
      end

      define_pione_method(">>>", [TypeRuleExpr], TypeRuleExpr) do |vtable, rec, other|
        ticket_expr = TicketExpr.new(rec.path).to_seq
        left = rec.add_output_ticket_expr(ticket_expr)
        right = other.add_input_ticket_expr(ticket_expr)
        CompositionalRuleExpr.new(left, right)
      end
    end
  end
end
