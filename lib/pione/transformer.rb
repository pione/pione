require 'pione/common'

module Pione
  class Document
    class UnknownAttribution < StandardError
      def initialize(t, identifier)
        @t = t
        @identifier = identifier
      end

      def message
        "Unknown attribution name '#{@identifier}' for #{@t}"
      end
    end
  end

  module TransformerModule
    class << self
      def included(mod)
        singleton = class << mod; self; end
        create_pair_by(Parslet, Parslet::Transform).each do |name, orig|
          singleton.__send__(:define_method, name) do |*args, &b|
            orig.__send__(name, *args, &b)
          end
        end

        class << mod
          def included(klass)
            name = :@__transform_rules
            klass_rules = klass.instance_variable_get(name)
            klass_rules = klass_rules ? klass_rules + rules : rules
            klass.instance_variable_set(name, klass_rules)
          end
        end
      end

      private

      def create_pair_by(*mods)
        mods.inject([]) do |list, mod|
          list += create_pair(mod)
        end
      end

      def create_pair(mod)
        (mod.methods.sort - Object.methods.sort).map{|m| [m, mod]}
      end
    end
  end

  class Transformer < Parslet::Transform
    require 'pione/transformer/literal'
    require 'pione/transformer/feature-expr'
    require 'pione/transformer/expr'
    require 'pione/transformer/flow-element'

    include Literal
    include FeatureExpr
    include Expr
    include FlowElement

    def initialize(data={})
      super()
      @package = data[:package]
    end

    #
    # statement
    #

    # package
    rule(:package => subtree(:tree)) {
      Package.new(tree[:package_name].to_s)
    }

    #
    # rule
    #
    rule(:rule_definition => subtree(:tree)) {
      name = tree[:rule_header][:rule_name].to_s
      inputs = tree[:inputs]
      outputs = tree[:outputs]
      params = tree[:params]
      features = FeatureSet.new(tree[:features])
      flow_block = tree[:flow_block]
      action_block = tree[:action_block]
      if flow_block
        Rule::FlowRule.new(name, inputs, outputs, params, features, flow_block)
      else
        body = action_block[:body].to_s
        Rule::ActionRule.new(name, inputs, outputs, params, features, body)
      end
    }

    #
    # rule conditions
    #

    # input_line
    rule(:input_line => subtree(:input)) {
      data_expr = input[:data]
      if input[:input_header] == "input-all"
        data_expr.all
      else
        data_expr
      end
    }

    # output_line
    rule(:output_line => subtree(:output)) {
      data_expr = output[:data]
      if output[:output_header] == "output-all"
        data_expr.all
      else
        data_expr
      end
    }

    # param_line
    rule(:param_line => subtree(:param)) {
      param[:variable].to_s
    }

    # feature_line
    rule(:feature_line => subtree(:tree)) {
      tree[:feature_expr].to_s
    }

    #
    # expression
    #

    # data_expr
    rule(:data_expr => subtree(:tree)) {
      data_name = tree[:data_name].to_s.gsub(/\\(.)/) {$1}
      elt = DataExpr.new(data_name)
      tree[:attributions].each do |attr|
        attribution_name = attr[:attribution_name]
        arguments = attr[:arguments]
        case attribution_name.to_s
        when "except"
          elt.except(*arguments)
        when "stdout"
          elt.stdout
        else
          raise UnknownAttribution.new('data', attribution_name)
        end
      end
      elt
    }

    # rule_expr
    rule(:rule_expr => subtree(:tree)) {
      rule_name = tree[:rule_name].to_s
      elt = RuleExpr.new(rule_name)
      tree[:attributions].each do |attr|
        attribution_name = attr[:attribution_name]
        arguments = attr[:arguments]
        begin
          elt.set_attribution(attribution_name.to_s, arguments)
        rescue UnknownRuleExprAttribution
          raise UnknownAttribution.new('rule', attribution_name)
        end
      end
      elt
    }
  end
end
