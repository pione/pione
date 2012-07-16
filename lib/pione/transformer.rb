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
    require 'pione/transformer/block'
    require 'pione/transformer/rule-definition'

    include Literal
    include FeatureExpr
    include Expr
    include FlowElement
    include Block
    include RuleDefinition

    def initialize(package=Package.new("main"))
      super()
      @current_package = package
    end

    def check_model_type(data, type)
      data.pione_model_type == type
    end

    #
    # statement
    #

    # package
    rule(:package => subtree(:tree)) {
      @current_package = Package.new(tree[:package_name].to_s)
    }
  end
end
