module Pione::Model
  # RuleCondition represents rule condition.
  class RuleCondition < PioneModelObject
    # Returns the value of attribute inputs.
    # @return [Array<DataExpr, Array<DataExpr>>]
    #   rule inputs condition
    attr_reader :inputs

    # Returns the value of attribute outputs.
    # @return [Array<DataExpr, Array<DataExpr>>]
    #  rule outputs condition
    attr_reader :outputs

    # Returns the value of attribute params.
    # @return [Parameters]
    #   rule parameters table
    attr_reader :params

    # Returns the value of attribute features.
    # @return [Feature]
    #   rule feature condition
    attr_reader :features

    # Creates a rule condition.
    # @param [Array<DataExpr, Array<DataExpr>>] inputs
    #   rule inputs
    # @param [Array<DataExpr, Array<DataExpr>>] outputs
    #   rule outputs
    # @param [Parameters] params
    #   rule parameters
    # @param [Feature] features
    #   rule features
    def initialize(inputs, outputs, params, features)
      check_argument_type(params, Parameters)
      check_argument_type(features, Feature::Expr)
      @inputs = inputs
      @outputs = outputs
      @params = params
      @features = features
      super()
    end

    # Returns true if the condition includes variable.
    # @return [Boolean]
    #   true if the condition includes variable, or false
    def include_variable?
      [ @inputs.any? {|input| input.include_variable?},
        @outputs.any? {|output| output.include_variable?},
        @params.include_variable?,
        @features.include_variable?
      ].any?
    end

    # @api private
    def ==(other)
      return false unless @inputs == other.inputs
      return false unless @outputs == other.outputs
      return false unless @params == other.params
      return false unless @features == other.features
      return true
    end

    alias :eql? :"=="

    # @api private
    def hash
      @inputs.hash + @outputs.hash + @params.hash + @features.hash
    end
  end

  # Rule is a class for PIONE rule model.
  class Rule < PioneModelObject
    extend Forwardable

    # Returns rule type.
    def self.rule_type
      @rule_type
    end

    # Returns the value of attribute expr.
    # @return [Array<DataExpr, Array<DataExpr>>]
    #   rule inputs condition
    attr_reader :expr

    attr_reader :condition
    attr_reader :body

    def_delegators :@condition, :inputs, :outputs, :params, :features

    # Creates a rule.
    # @param [RuleExpr] expr
    #   rule expression
    # @param [RuleCondition] condition
    #   rule condition
    # @param [Block] body
    #   rule body block
    def initialize(expr, condition, body)
      @expr = expr
      @condition = condition
      @body = body
    end

    # Returns the rule path.
    # @return [String]
    #   rule path
    def rule_path
      @expr.rule_path
    end

    # Returns true if expression, condition, or body include variables.
    # @return [Boolean]
    #   true if expression, condition, or body include variables
    def include_variable?
      return true if @expr.include_variable?
      return true if @condition.include_variable?
      return true if @body.include_variable?
      return false
    end

    # Returns true if this is a kind of action rule.
    # @return [Boolean]
    #   true if this is a kind of action rule, or false
    def action?
      self.class.rule_type == :action
    end

    # Returns true if this is a kind of flow rule.
    # @return [Boolean]
    #   true if this is a kind of flow rule, or false
    def flow?
      self.class.rule_type == :flow
    end

    # Makes a task handler object for the rule.
    # @param [TupleSpaceServer] ts_server
    #   tuple space server
    # @param [Array<Data, Array<Data>>] inputs
    #   input tuples
    # @param [Parameters] params
    #   rule parameters
    # @param [Array<String>] call_stack
    #   call stack
    # @return [RuleHandler]
    #   rule handler object
    def make_handler(ts_server, inputs, params, call_stack, opts={})
      handler_class.new(ts_server, self, inputs, params, call_stack, opts)
    end

    # Returns a rule handler class.
    # @api private
    def handler_class
      raise NotImplementedError
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      return false unless @expr == other.expr
      return false unless @condition == other.condition
      return false unless @body == other.body
      return true
    end

    alias :eql? :"=="

    # @api private
    def hash
      @expr.hash + @condition.hash + @body.hash
    end
  end

  # ActionRule is a rule writing action.
  class ActionRule < Rule
    @rule_type = :action

    # @api private
    def handler_class
      RuleHandler::ActionHandler
    end
  end

  # FlowRule represents a flow structured rule. This rule is consisted by flow
  # elements and executes elements actions.
  class FlowRule < Rule
    @rule_type = :flow

    # @api private
    def handler_class
      RuleHandler::FlowHandler
    end
  end

  # RootRule is a hidden toplevel flow rule like the following:
  #   Rule Root
  #     input  '*'.all
  #     output '*'.all.except('{$INPUT[1]}')
  #   Flow
  #     rule &main:Main
  #   End
  class RootRule < FlowRule
    INPUT_DOMAIN = 'input'

    # root domain has no digest and no package
    ROOT_DOMAIN = 'root'

    attr_reader :main

    # Makes a rule.
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

    # @api private
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
        [],
        {:domain => @domain}
      )
    end

    private

    # @api private
    def make_condition
      inputs = @main.inputs
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

    # @api private
    def handler_class
      RuleHandler::RootHandler
    end
  end

  # SystemRule represents built-in rule definition. System rules belong to
  # 'system' package.
  class SystemRule < ActionRule
    # Creates a system rule model.
    # @param [String] name
    #   rule name
    # @param [Proc] b
    #   rule process
    def initialize(name, &b)
      expr = RuleExpr.new(Package.new('system'), name)
      condition = make_condition
      super(expr, condition, b)
    end

    private

    # @api private
    def make_condition
      inputs = [DataExpr.new('*')]
      RuleCondition.new(inputs, [], Parameters.empty, Feature::EmptyFeature.new)
    end

    # @api private
    def handler_class
      RuleHandler::SystemHandler
    end
  end

  # &System:Terminate rule
  SYSTEM_TERMINATE = SystemRule.new('Terminate') do |tuple_space_server|
    user_message "!!!!!!!!!!!!!!!!!"
    user_message "!!! Terminate !!!"
    user_message "!!!!!!!!!!!!!!!!!"
    tuple_space_server.write(Tuple[:command].new("terminate"))
  end

  SYSTEM_RULES = [ SYSTEM_TERMINATE ]
end
