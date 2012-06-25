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
    attr_accessor :package

    def initialize(expr)
      @expr = expr
    end

    # Return a rule path with expanding variables.
    def rule_path(vtable=VariableTable.new)
      @expr.eval(vtable)
    end

    # Returns true if sync mode.
    def sync_mode?
      @expr.sync_mode?
    end

    def ==(other)
      @expr == expr
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @expr.hash
    end
  end
end
