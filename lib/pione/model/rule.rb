module Pione
  module Model
    # RuleCondition represents rule condition.
    class RuleCondition < BasicModel
      # @return [Array<DataExpr, Array<DataExpr>>]
      #   input data condition
      attr_reader :inputs

      # @return [Array<DataExpr, Array<DataExpr>>]
      #   output data condition
      attr_reader :outputs

      forward_as_key! :@condition, :params, :features, :constraints, :input_ticket_expr, :output_ticket_expr

      # Create a rule condition.
      #
      # @param inputs [Array<DataExpr>]
      #   input conditions
      # @param outputs [Array<DataExpr>]
      #   output conditions
      # @param condition [Hash]
      # @option condition [Parameters] params
      #   rule parameters
      # @option condition [Feature] features
      #   rule features
      # @option condition [TicketExpr] input_ticket_expr
      #   input ticket
      # @option condition [TicketExpr] output_ticket_expr
      #   output ticket
      def initialize(inputs, outputs, condition={})
        @inputs = inputs
        @outputs = outputs
        @condition = {}
        @condition[:params] = condition[:params] || Parameters.empty
        @condition[:features] = condition[:features] || Feature.empty
        @condition[:constraints] = condition[:constraints] || Constraints.empty
        @condition[:input_ticket_expr] = condition[:input_ticket_expr] || TicketExprSequence.empty
        @condition[:output_ticket_expr] = condition[:output_ticket_expr] || TicketExprSequence.empty
        super()
      end

      # Return true if the condition includes variable.
      #
      # @return [Boolean]
      #   true if the condition includes variable, or false
      def include_variable?
        return true if @inputs.any? {|input| input.include_variable?}
        return true if @outputs.any? {|output| output.include_variable?}
        return true if @condition.any? {|key, val| val.include_variable?}
        return false
      end

      def to_hash
        @condition.merge(inputs: @inputs, outputs: @outputs)
      end

      # @api private
      def ==(other)
        to_hash == other.to_hash
      end
      alias :eql? :"=="

      # @api private
      def hash
        @inputs.hash + @outputs.hash + @condition.hash
      end
    end

    # Rule is a class for PIONE rule model.
    class Rule < BasicModel
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

      # @return [RuleExpr]
      #   rule expression
      attr_reader :rule_expr

      # @return [RuleCondition]
      #   rule condition
      attr_reader :condition

      # @return [Object]
      #   rule body
      attr_reader :body

      forward! :@condition, :inputs, :outputs, :params, :features, :constraints
      forward! :@condition, :input_ticket_expr, :output_ticket_expr
      forward! :class, :rule_type, :handler_class
      forward! :@rule_expr, :rule_path

      # Create a rule.
      #
      # @param rule_expr [RuleExpr]
      #   rule expression
      # @param condition [RuleCondition]
      #   rule condition
      # @param [Block] body
      #   rule body block
      def initialize(rule_expr, condition, body)
        @rule_expr = rule_expr
        @condition = condition
        @body = body
      end

      # Return true if expression, condition, or body include variables.
      #
      # @return [Boolean]
      #   true if expression, condition, or body include variables
      def include_variable?
        return true if @rule_expr.include_variable?
        return true if @condition.include_variable?
        return true if @body.include_variable?
        return false
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

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless @rule_expr == other.rule_expr
        return false unless @condition == other.condition
        return false unless @body == other.body
        return true
      end

      alias :eql? :"=="

      # @api private
      def hash
        @rule_expr.hash + @condition.hash + @body.hash
      end
    end

    # ActionRule is a rule that have some actions. This rule makes data
    # processing.
    class ActionRule < Rule
      set_rule_type :action
      set_handler_class RuleHandler::ActionHandler
    end

    # FlowRule is a rule that have flow elements. This rule makes flows of PIONE
    # processing.
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
      ROOT_DOMAIN = 'root'

      attr_reader :main

      # Make a rule.
      #
      # @param main [Rule]
      #   main rule
      # @param params [Parameters]
      #   main rule's parameters
      def initialize(main, params=Parameters.empty)
        @main = main
        @params = params
        super(
          RuleExpr.new(Package.new("root"), "Root"),
          RuleCondition.new(@main.inputs, @main.outputs),
          FlowBlock.new(CallRule.new(@main.rule_expr.set_params(@params)))
        )
        @domain = ROOT_DOMAIN
      end

      # @api private
      def make_handler(ts_server)
        # build parameter
        params = @main.params.merge(@params)

        # find inputs
        finder = DataFinder.new(ts_server, INPUT_DOMAIN)
        results = finder.find(:input, inputs, params.as_variable_table)
        if results.empty? and not(@main.inputs.empty?)
          return nil
        end
        inputs = @main.inputs.empty? ? [] : results.first.combination

        # make handler
        handler_class.new(
          ts_server,
          self,
          inputs,
          params,
          [],
          {:domain => @domain}
        )
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
        expr = RuleExpr.new(Package.new('system'), name)
        condition = RuleCondition.new([DataExpr.new('*').to_seq.set_all], [])
        super(expr, condition, b)
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
end
