module Pione::Model
  class RuleCondition < PioneModelObject
    attr_reader :inputs
    attr_reader :outputs
    attr_reader :params
    attr_reader :features

    def initialize(inputs, outputs, params, features)
      raise ArgumentError.new(params) unless params.kind_of?(Parameters)
      raise ArgumentError.new(features) unless features.kind_of?(Feature::Expr)
      @inputs = inputs
      @outputs = outputs
      @params = params
      @features = features
      super()
    end

    def include_variable?
      @inputs.any?{|input| input.include_variable?} ||
        @outputs.any?{|output| output.include_variable?} ||
        @params.include_variable? ||
        @features.include_variable?
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

    def rule_path
      @expr.rule_path
    end

    def include_variable?
      @expr.include_variable? ||
        @condition.include_variable? ||
        @body.include_variable?
    end

    def self.rule_type
      @rule_type
    end

    def inputs
      @condition.inputs
    end

    def outputs
      @condition.outputs
    end

    def params
      @condition.params
    end

    def features
      @condition.features
    end

    # Return true.
    def action?
      self.class.rule_type == :action
    end

    # Return false.
    def flow?
      self.class.rule_type == :flow
    end

    # Make task handler object for the rule.
    def make_handler(ts_server, inputs, params, opts={})
      handler_class.new(ts_server, self, inputs, params, opts)
    end

    def handler_class
      raise NotImplementedError
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

    def handler_class
      RuleHandler::ActionHandler
    end
  end

  # FlowRule represents a flow structured rule. This rule is consisted by flow
  # elements and executes elements actions.
  class FlowRule < Rule
    @rule_type = :flow

    def handler_class
      RuleHandler::FlowHandler
    end
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

    attr_reader :main

    # Make new rule.
    def initialize(main, params=Parameters.empty)
      @main = main
      @params = params
      condition = make_condition
      super(
        RuleExpr.new(Package.new("root"), "Root"),
        condition,
        FlowBlock.new(CallRule.new(@main.expr.set_params(@params)))
      )
      @domain = ROOT_DOMAIN
    end

    def make_condition
      inputs  = @main.inputs
      outputs =
        if inputs.empty?
          [DataExpr.all("*")]
        else
          [DataExpr.all("*").except("{$INPUT[1]}")]
        end
      RuleCondition.new(
        inputs,
        outputs,
        Parameters.empty,
        Feature.empty
      )
    end

    def make_handler(ts_server)
      finder = DataFinder.new(ts_server, INPUT_DOMAIN)
      results = finder.find(:input, inputs, VariableTable.new)
      if results.empty? and not(@main.inputs.empty?)
        return nil
      end
      inputs = @main.inputs.empty? ? [] : results.first.combination
      handler_class.new(
        ts_server,
        self,
        inputs,
        @params,
        {:domain => @domain}
      )
    end

    def handler_class
      RuleHandler::RootHandler
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
      RuleCondition.new(inputs, [], Parameters.empty, Feature::EmptyFeature.new)
    end

    def handler_class
      RuleHandler::SystemHandler
    end
  end

  SYSTEM_TERMINATE = SystemRule.new('Terminate') do |tuple_space_server|
    user_message "!!!!!!!!!!!!!!!!!"
    user_message "!!! Terminate !!!"
    user_message "!!!!!!!!!!!!!!!!!"
    tuple_space_server.write(Tuple[:command].new("terminate"))
  end

  SYSTEM_RULES = [ SYSTEM_TERMINATE ]
end
