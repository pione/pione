module Pione
  # RuleEngine is a namespace for rule engine classes.
  module RuleEngine
    def self.make(space, env, package_id, rule_name, inputs, param_set, domain_id, caller_id)
      rule_definition = env.rule_get(Lang::RuleExpr.new(rule_name, package_id))
      handler =
        case rule_definition
        when Lang::FlowRuleDefinition  ; FlowHandler
        when Lang::ActionRuleDefinition; ActionHandler
        when Lang::EmptyRuleDefinition ; EmptyHandler
        when Lang::RootRuleDefinition  ; RootHandler
        end
      handler.new(space, env, package_id, rule_name, rule_definition, inputs, param_set, domain_id, caller_id)
    end
  end
end

require 'pione/rule-engine/engine-exception'
require 'pione/rule-engine/data-finder'
require 'pione/rule-engine/basic-handler'
require 'pione/rule-engine/update-criteria'
require 'pione/rule-engine/flow-handler'
require 'pione/rule-engine/action-handler'
require 'pione/rule-engine/root-handler'
require 'pione/rule-engine/system-handler'
require 'pione/rule-engine/empty-handler'

