require 'innocent-white/common'

module InnocentWhite
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
    attr_reader :package
    attr_reader :name

    # Create a rule expression.
    # package:: package name of the rule
    # name:: the rule name
    def initialize(package, name)
      @package = package
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
        params = arguments.map{|t| t.to_s}
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

    def params(*values)
      @params = values
      return self
    end
  end
end
