module Pione::Model
  # Rule representation in the flow element context.
  class RuleExpr < BasicModel
    set_pione_model_type TypeRuleExpr

    attr_reader :package
    attr_reader :name
    attr_reader :params
    attr_reader :input_ticket_expr
    attr_reader :output_ticket_expr

    # Create a rule expression.
    #
    # @param package [String]
    #   package name
    # @param name [String]
    #   rule name
    # @param params [Parameters]
    #   parameters
    # @param input_ticket_expr [TicketExpr]
    #   input ticket condition
    # @param output_ticket_expr [TicketExpr]
    #   output ticket condition
    def initialize(package, name, params, input_ticket_expr, output_ticket_expr)
      @package = package
      @name = name
      @params = params
      @input_ticket_expr = input_ticket_expr
      @output_ticket_expr = output_ticket_expr
      super()
    end

    # Returns rule path form.
    # @return [String]
    #   rule path string
    def path
      "&%s:%s" % [@package.name, @name]
    end

    # FIXME
    def rule_path
      raise UnboundVariableError.new(self) if @package.include_variable?
      "&%s:%s" % [@package.name, @name]
    end

    # @api private
    def task_id_string
      "RuleExpr<%s,#{@name}>" % [@package.task_id_string]
    end

    # @api private
    def textize
      "rule_expr(%s,\"%s\")" % [@package.textize, @name]
    end

    # Create a new rule expression with adding the ticket expression as input
    # condition.
    #
    # @param ticket_expr [TicketExpr]
    #   ticket expression as additional input condition
    # @return [RuleExpr]
    #   new rule expression
    def add_input_ticket_expr(ticket_expr)
      return self.class.new(@package, @name, @params, @input_ticket_expr + ticket_expr, @output_ticket_expr)
    end

    # Create a new rule expression with adding the ticket expression as output
    # condition.
    #
    # @param ticket_expr [TicketExpr]
    #   ticket expression as additional output condition
    # @return [RuleExpr]
    #   new rule expression
    def add_output_ticket_expr(ticket_expr)
      return self.class.new(@package, @name, @params, @input_ticket_expr, @output_ticket_expr + ticket_expr)
    end

    # Sets a package name and returns a new expression.
    # @param [String] package
    #   package name
    # @return [RuleExpr]
    #   new rule expression with the package name
    def set_package(package)
      return self.class.new(package, @name, @params)
    end

    # Sets parameters and returns a new expression.
    # @param [Parameters] params
    #   parameters
    # @return [RuleExpr]
    #   new rule expression with the parameters
    def set_params(params)
      return self.class.new(@package, @name, params, @input_ticket_expr, @output_ticket_expr)
    end

    # Evaluates the object with the variable table.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [BasicModel]
    #   evaluation result
    def eval(vtable)
      return self.class.new(
        @package.eval(vtable),
        @name,
        @params.eval(vtable),
        @input_ticket_expr.eval(vtable),
        @output_ticket_expr.eval(vtable)
      )
    end

    # Returns true if the package or parameters include variables.
    # @return [Boolean]
    #   true if the package or parameters include variables
    def include_variable?
      [ @package.include_variable?,
        @params.include_variable?,
        @input_ticket_expr.include_variable?,
        @output_ticket_expr.include_variable?
      ].any?
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @package = other.package
      return false unless @name == other.name
      return false unless @params == other.params
      return true
    end

    # @api private
    alias :eql? :"=="

    # @api private
    def hash
      @package.hash + @name.hash + @params.hash
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

    # Evaluates left and right expressions with the variable table.
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

  TypeRuleExpr.instance_eval do
    define_pione_method("==", [TypeRuleExpr], TypeBoolean) do |rec, other|
      PioneBoolean.new(
        rec.package == other.package &&
        rec.name == other.name &&
        rec.params == other.params)
    end

    define_pione_method("!=", [TypeRuleExpr], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("params", [TypeParameters], TypeRuleExpr) do |rec, params|
      rec.set_params(params)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.name)
    end

    define_pione_method("==>", [TypeTicketExpr], TypeRuleExpr) do |rec, ticket_expr|
      rec.add_output_ticket_expr(ticket_expr)
    end

    define_pione_method(">>>", [TypeRuleExpr], TypeRuleExpr) do |rec, other|
      ticket_expr = TicketExpr.new([rec.path])
      left = rec.add_output_ticket_expr(ticket_expr)
      right = other.add_input_ticket_expr(ticket_expr)
      CompositionalRuleExpr.new(left, right)
    end
  end
end
