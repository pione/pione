module Pione::Model
  # Unknown attribution for RuleExpr.
  class UnknownRuleExprAttribution < Exception
    def initialize(name)
      @name = name
    end

    def message
      "Unknown attribution name '#{@name}' in the context of RuleExpr"
    end
  end

  # Rule representation in the flow element context.
  class RuleExpr
    attr_reader :name
    attr_reader :params

    # Create a rule expression.
    # name:: the rule name
    def initialize(name)
      @name = name
      @sync_mode = false
      @params = []
    end

    # Set a attribution.
    def set_attribution(attribution_name, arguments)
      case attribution_name
      when "sync"
        sync(true)
      when "params"
        @params = arguments.map{|t| t.to_s}
      else
        raise UnknownRuleExprAttribution.new(attribution_name)
      end
    end

    # Return true if sync mode.
    def sync_mode?
      @sync_mode
    end

    def sync(truth)
      @sync_mode = truth
      return self
    end

    def eval
      @name
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @name == other.name
      return false unless sync_mode? == other.sync_mode?
      return false unless @params == other.params
      return true
    end

    alias :eql? :==

    def hash
      @name.hash + @params.hash + @sync_mode.hash
    end
  end
end
