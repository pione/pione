module Pione
  module Model
    # RuleCondition represents rule condition.
    class RuleCondition < BasicModel
      # the value of attribute inputs
      #
      # @return [Array<DataExpr, Array<DataExpr>>]
      #   rule inputs condition
      attr_reader :inputs

      # the value of attribute outputs
      #
      # @return [Array<DataExpr, Array<DataExpr>>]
      #   rule outputs condition
      attr_reader :outputs

      # the value of attribute params
      #
      # @return [Parameters]
      #   rule parameters table
      attr_reader :params

      # the value of attribute features
      #
      # @return [Feature]
      #   rule feature condition
      attr_reader :features

      # input ticket expression
      #
      # @return [TicketExpr]
      #    input ticket expression
      attr_reader :input_ticket_expr

      # output ticket expression
      #
      # @return [TicketExpr]
      #    output ticket
      attr_reader :output_ticket_expr

      # Create a rule condition.
      #
      # @param inputs [Array<DataExpr, Array<DataExpr>>]
      #   rule inputs
      # @param outputs [Array<DataExpr, Array<DataExpr>>]
      #   rule outputs
      # @param params [Parameters]
      #   rule parameters
      # @param features [Feature]
      #   rule features
      # @param input_ticket_expr [TicketExpr]
      #   input ticket expression
      # @param output_ticket_expr [TicketExpr]
      #   output ticket expression
      def initialize(inputs, outputs, params, features, input_ticket_expr, output_ticket_expr)
        check_argument_type(params, Parameters)
        check_argument_type(features, Feature::Expr)
        @inputs = inputs
        @outputs = outputs
        @params = params
        @features = features
        @input_ticket_expr = input_ticket_expr
        @output_ticket_expr = output_ticket_expr
        super()
      end

      # Return true if the condition includes variable.
      #
      # @return [Boolean]
      #   true if the condition includes variable, or false
      def include_variable?
        [ @inputs.any? {|input| input.include_variable?},
          @outputs.any? {|output| output.include_variable?},
          @params.include_variable?,
          @features.include_variable?,
          @input_tickets.any? {|ticket| ticket.include_variable?},
          @output_tickets.any? {|ticket| ticket.include_variable?}
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
    class Rule < BasicModel
      extend Forwardable

      # Returns rule type.
      def self.rule_type
        @rule_type
      end

      # Return the value of attribute expr.
      #
      # @return [Array<DataExpr, Array<DataExpr>>]
      #   rule inputs condition
      attr_reader :expr

      attr_reader :condition
      attr_reader :body

      forward! :@condition, :inputs, :outputs, :params, :features
      forward! :@condition, :input_ticket_expr, :output_ticket_expr
      forward :class, :rule_type

      # Create a rule.
      #
      # @param expr [RuleExpr]
      #   rule expression
      # @param condition [RuleCondition]
      #   rule condition
      # @param [Block] body
      #   rule body block
      def initialize(expr, condition, body)
        @expr = expr
        @condition = condition
        @body = body
      end

      # Return the rule path.
      #
      # @return [String]
      #   rule path
      def rule_path
        @expr.rule_path
      end

      # Return true if expression, condition, or body include variables.
      #
      # @return [Boolean]
      #   true if expression, condition, or body include variables
      def include_variable?
        return true if @expr.include_variable?
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
      # @param inputs [Array<Data, Array<Data>>]
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

      # Return a rule handler class.
      #
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

      # Make a rule.
      #
      # @param main [Rule]
      #   main rule
      # @param params [Parameters]
      #   main rule's parameters
      def initialize(main, params=Parameters.empty)
        @main = main
        @params = params
        condition = make_condition
        super(
          RuleExpr.new(Package.new("root"), "Root", Parameters.empty, TicketExpr.empty, TicketExpr.empty),
          condition,
          FlowBlock.new(CallRule.new(@main.expr.set_params(@params)))
        )
        @domain = ROOT_DOMAIN
      end

      # @api private
      def make_handler(ts_server)
        finder = DataFinder.new(ts_server, INPUT_DOMAIN)
        results = finder.find(:input, inputs, @params.as_variable_table)
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
        RuleCondition.new(
          @main.inputs,
          @main.outputs,
          Parameters.empty,
          Feature.empty,
          TicketExpr.empty,
          TicketExpr.empty
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
      # Create a system rule model.
      #
      # @param name [String]
      #   rule name
      # @param [Proc] b
      #   rule process
      def initialize(name, &b)
        expr = RuleExpr.new(
          Package.new('system'),
          name,
          Parameters.empty,
          TicketExpr.empty,
          TicketExpr.empty
        )
        condition = make_condition
        super(expr, condition, b)
      end

      private

      # @api private
      def make_condition
        inputs = [DataExpr.new('*')]
        RuleCondition.new(inputs, [], Parameters.empty, Feature::EmptyFeature.new, TicketExpr.empty, TicketExpr.empty)
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
end
