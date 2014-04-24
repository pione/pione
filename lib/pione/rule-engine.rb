module Pione
  # RuleEngine is a namespace for rule engine classes.
  module RuleEngine
    require 'pione/rule-engine/engine-exception'
    require 'pione/rule-engine/data-finder'
    require 'pione/rule-engine/basic-handler'
    require 'pione/rule-engine/update-criteria'
    require 'pione/rule-engine/flow-handler'
    require 'pione/rule-engine/action-handler'
    require 'pione/rule-engine/root-handler'
    require 'pione/rule-engine/system-handler'
    require 'pione/rule-engine/empty-handler'

    # Relation from rule definition to the handler.
    HANDLER = {
      Lang::FlowRuleDefinition   => FlowHandler,
      Lang::ActionRuleDefinition => ActionHandler,
      Lang::EmptyRuleDefinition  => EmptyHandler,
      Lang::RootRuleDefinition   => RootHandler
    }

    # Make a rule handler with target rule's informations.
    #
    # @param [Hash.new] param
    # @option param [String] :package_id
    #   package ID
    # @option param [String] :rule_name
    #   rule name
    # @option param [Array] :inputs
    #   input data
    # @option param [Object] :param_set
    #   parameter set
    # @option param [String] :domain_id
    #   domain ID
    # @option param [String] :caller_id
    #   caller ID
    # @option param [URI] :request_from
    #   URI that the client requested the job from
    # @option param [String] :session_id
    #   session ID
    def self.make(param)
      # check requisite parameters
      requisites = [:tuple_space, :env, :package_id, :rule_name, :inputs, :param_set, :domain_id, :caller_id]
      requisites.each do |requisite|
        unless param.has_key?(requisite)
          raise ArgumentError.new("parameter '%s' is requisite for rule engine." % requisite)
        end
      end

      # make a rule handler
      rule_definition = param[:env].rule_get(Lang::RuleExpr.new(param[:rule_name], param[:package_id]))
      HANDLER[rule_definition.class].new(param.merge(rule_definition: rule_definition))
    end
  end
end

