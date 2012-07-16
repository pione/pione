module Pione::Model
  class RuleCondition < PioneModelObject
    attr_reader :inputs
    attr_reader :outputs
    attr_reader :params
    attr_reader :features

    def initialize(inputs, outputs, params, features)
      @inputs = inputs
      @outputs = outputs
      @params = params
      @features = features
    end

    def ==(other)
      return false unless @inputs == other.inputs
      return false unless @outputs == other.outputs
      return false unless @params == other.params
      return false unless @features == other.features
      return true
    end

    alias :eql? :==

    def hash
      @inputs.hash + @outputs.hash + @params.hash + @features.hash
    end
  end

  class Rule < PioneModelObject
    attr_reader :expr
    attr_reader :condition
    attr_reader :body

    def initialize(expr, condition, body)
      @expr = expr
      @condition = condition
      @body = body
    end

    def rule_path(vtable)
      @expr.eval(vtable)
    end

    def self.rule_type
      @rule_type
    end

    # Return true.
    def action?
      self.class.rule_type == :action
    end

    # Return false.
    def flow?
      self.class.rule_type == :flow
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @expr == other.expr
      return false unless @condition == other.condition
      return false unless @body == other.body
      return true
    end

    alias :eql? :==

    def hash
      @expr.hash + @condition.hash + @body.hash
    end
  end

  # ActionRule is a rule writing action.
  class ActionRule < Rule
    @rule_type = :action
  end

  # FlowRule represents a flow structured rule. This rule is consisted by flow
  # elements and executes elements actions.
  class FlowRule < Rule
    @rule_type = :flow
  end

  # RootRule is a hidden toplevel rule like the following:
  #   Rule Root
  #     input-all  '*'
  #     output-all '*'.except('{$INPUT[1]}')
  #   Flow
  #     rule /Main
  #   End
  class RootRule < FlowRule
    INPUT_DOMAIN = '/input'
    ROOT_DOMAIN = '/root'

    # Make new rule.
    def initialize(rule_path)
      package = RootPackage.new
      name = 'root'
      condition = make_condition
      body = [FlowElement::CallRule.new(rule_path)]
      super(package, name, condition, body)
      @domain = ROOT_DOMAIN
    end

    def make_condition
      inputs  = [ DataExpr.all("*")]
      outputs = [ DataExpr.all("*").except("{$INPUT[1]}") ]
      RuleCondition.new(inputs, outputs, [], [])
    end

    def make_handler(ts_server)
      finder = DataFinder.new(ts_server, INPUT_DOMAIN)
      results = finder.find(:input, @inputs)
      return nil if results.empty?
      handler_class.new(ts_server,
                        self,
                        results.first.combination,
                        [],
                        {:domain => @domain})
    end
  end

  # SystemRule represents built-in rule definition.
  class SystemRule < ActionRule
    def initialize(name, &b)
      expr = RuleExpr.new(Package.new('system'), name)
      condition = make_condition
      super(expr, condition, b)
    end

    def make_condition
      inputs = [DataExpr.new('*')]
      RuleCondition.new(inputs, [], [], [])
    end
  end
end
