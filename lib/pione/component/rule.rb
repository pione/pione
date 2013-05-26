module Pione
  module Component
    # RuleCondition represents rule condition.
    class RuleCondition < StructX
      include Util::VariableHoldable

      member :inputs, default: []
      member :outputs, default: []
      member :params, default: Model::Parameters.empty
      member :features, default: Model::Feature.empty
      member :constraints, default: Model::Constraints.empty
      member :input_ticket_expr, default: Model::TicketExprSequence.empty
      member :output_ticket_expr, default: Model::TicketExprSequence.empty

      hold_variables members
    end

    # Rule is a class for PIONE rule model.
    class Rule < PioneObject
      include SimpleIdentity
      include Util::VariableHoldable

      hold_variables :rule_expr, :condition, :body

      class << self
        attr_reader :rule_type
        attr_reader :handler_class

        # Declare rule type of the class.
        #
        # @param rule_type [Symbol]
        #   rule type
        # @return [void]
        def set_rule_type(rule_type)
          @rule_type = rule_type
        end

        # Declare rule handler class of the class.
        #
        # @param handler_class [Class]
        #   handler class
        # @return [void]
        def set_handler_class(handler_class)
          @handler_class = handler_class
        end
      end

      forward! :class, :rule_type, :handler_class

      attr_reader :package_name
      attr_reader :name
      attr_reader :condition
      attr_reader :body

      # Create a rule.
      #
      # @param package_name [String]
      #   package name
      # @param name [String]
      #   rule name
      # @param condition [RuleCondition]
      #   rule condition
      # @param [Block] body
      #   rule body block
      def initialize(package_name, name, condition, body)
        @package_name = package_name
        @name = name
        @condition = condition
        @body = body
      end

      # Return true if this is a kind of action rule.
      #
      # @return [Boolean]
      #   true if this is a kind of action rule, or false
      def action?
        rule_type == :action
      end

      # Return true if this is a kind of flow rule.
      #
      # @return [Boolean]
      #   true if this is a kind of flow rule, or false
      def flow?
        rule_type == :flow
      end

      def path
        "&%s:%s" % [@package_name, @name]
      end

      # Make a task handler object for the rule.
      #
      # @param ts_server [TupleSpaceServer]
      #   tuple space server
      # @param inputs [Array<DataTuple, Array<DataTuple>>]
      #   input tuples
      # @param params [Parameters]
      #   rule parameters
      # @param call_stack [Array<String>]
      #   call stack
      # @return [RuleHandler]
      #   rule handler object
      def make_handler(ts_server, inputs, params, call_stack, opts={})
        handler_class.new(ts_server, self, inputs, params, call_stack, opts)
      end
    end

    # ActionRule is a rule that have some actions. This rule makes data
    # processing.
    class ActionRule < Rule
      set_rule_type :action
      set_handler_class RuleHandler::ActionHandler
    end

    # FlowRule is a rule that have flow elements. This rule makes processing flow.
    class FlowRule < Rule
      set_rule_type :flow
      set_handler_class RuleHandler::FlowHandler
    end

    # EmptyRule is a rule that have no body. This rule is useful when you need
    # no flows and no actions.
    class EmptyRule < Rule
      set_rule_type :action
      set_handler_class RuleHandler::EmptyHandler
    end

    # RootRule is a hidden toplevel rule. This rule has same flow as the follow:
    #   Rule Root
    #     input  '*'.all
    #     output '*'.all.except('{$INPUT[1]}')
    #   Flow
    #     rule &main:Main
    #   End
    class RootRule < Rule
      set_rule_type :flow
      set_handler_class RuleHandler::RootHandler

      INPUT_DOMAIN = 'input'

      # root domain has no digest and no package
      ROOT_DOMAIN = 'Root'

      attr_reader :main

      # Make a root rule.
      #
      # @param main [Rule]
      #   main rule
      # @param params [Parameters]
      #   main rule's parameters
      def initialize(main, params=Parameters.empty)
        @main = main
        @params = params
        @domain = ROOT_DOMAIN
        rule_expr = RuleExpr.new(PackageExpr.new(main.package_name), main.name)
        condition = RuleCondition.new(@main.condition.inputs, @main.condition.outputs)
        block = FlowBlock.new(CallRule.new(rule_expr.set_params(@params)))
        super("Root", "Root", condition, block)
      end

      def make_handler(ts_server)
        # build parameter
        params = @main.condition.params.merge(@params)

        # find inputs
        finder = DataFinder.new(ts_server, INPUT_DOMAIN)
        results = finder.find(:input, @main.condition.inputs, params.as_variable_table)
        if results.empty? and not(@main.condition.inputs.empty?)
          return nil
        end
        inputs = @main.condition.inputs.empty? ? [] : results.first.combination

        # make handler
        handler_class.new(ts_server, self, inputs, params, [], domain: @domain)
      end
    end

    # SystemRule represents built-in rule definition. System rules belong to
    # 'system' package.
    class SystemRule < Rule
      set_rule_type :action
      set_handler_class RuleHandler::SystemHandler

      # Create a system rule model.
      #
      # @param name [String]
      #   rule name
      # @param [Proc] b
      #   rule process
      def initialize(name, &b)
        condition = RuleCondition.new([Model::DataExpr.new('*').to_seq.set_all], [])
        super('System', name, condition, b)
      end
    end

    # &System:Terminate rule
    SYSTEM_TERMINATE = SystemRule.new('Terminate') do |tuple_space_server|
      user_message "!!! Terminate processing !!!"
      tuple_space_server.write(Tuple[:command].new("terminate"))
    end

    SYSTEM_RULES = [ SYSTEM_TERMINATE ]
  end
end
