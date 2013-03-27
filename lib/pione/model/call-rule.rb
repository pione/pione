module Pione::Model
  # CallRule represents the application of a rule.
  # @example
  #   # simple rule calling:
  #   rule r1
  #   #=> CallRule.new(RuleExpr.new('r1'))
  # @example
  #   # with absolute path:
  #   rule /abc:a
  #   #=> CallRule.new(RuleExpr.new('/abc:a'))
  # @example
  #   # with variable:
  #   rule $X
  #   #=> CallRule.new(Variable.new('X'))
  class CallRule < BasicModel
    attr_reader :expr

    # Creates a callee rule.
    # @param [BasicModel] expr
    #   callee rule
    def initialize(expr)
      @expr = expr
      super()
    end

    # Returns a rule path string with expanding variables.
    # @return [String]
    #   rule path(package name and rule name)
    def rule_path
      if @expr.include_variable?
        raise UnboundVariableError.new(@expr)
      end
      @expr.rule_path
    end

    # Returns true if the expression has variables.
    # @return [Boolean]
    #   true if the expression has variables
    def include_variable?
      @expr.include_variable?
    end

    # Evaluates the expression.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [BasicModel]
    #   evaluation result
    def eval(vtable)
      self.class.new(@expr.eval(vtable))
    end

    # Return a set of call-rules that the rule expression are expanded.
    #
    # @return [Set<CallRule>]
    #   a set of call-rules
    def to_set
      @expr.to_set.map do |expr|
        self.class.new(expr)
      end
    end

    # @api private
    def textize
      "call_rule(%s)" % [@expr.textize]
    end

    # @api private
    def ==(other)
      @expr == other.expr
    end

    alias :eql? :==

    # @api private
    def hash
      @expr.hash
    end
  end
end
