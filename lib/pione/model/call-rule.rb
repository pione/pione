module Pione::Model
  # CallRule represents the application of a rule.
  # For example of simple rule calling:
  #   rule r1
  #   => CallRule.new(RuleExpr.new('r1'))
  #
  # For example with absolute path:
  #   rule /abc:a
  #   => CallRule.new(RuleExpr.new('/abc:a'))
  #
  # For example with variable:
  #   rule $X
  #   => CallRule.new(Variable.new('X'))
  class CallRule < PioneModelObject
    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end

    # Return a rule path string with expanding variables.
    def rule_path
      if @expr.include_variable?
        raise UnboundVariableError.new(@expr)
      end
      @expr.rule_path
    end

    def include_variable?
      @expr.include_variable?
    end

    # Returns true if sync mode.
    def sync_mode?
      @expr.sync_mode?
    end

    def eval(vtable)
      self.class.new(@expr.eval(vtable))
    end

    def textize
      "call_rule(%s)" % [@expr.textize]
    end

    def ==(other)
      @expr == other.expr
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @expr.hash
    end
  end
end
