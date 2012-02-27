require 'innocent-white/common'
require 'innocent-white/data-name-exp'
require 'innocent-white/rule'

module InnocentWhite
  class Document < InnocentWhiteObject
    class Definition
      def self.eval(&b)
        obj = new
        obj.instance_eval(&b)
        return obj
      end

      def all(name)
        Rule::DataName.all(name)
      end

      # Input statement.
      def inputs(*items)
        @inputs = items.map(&DataNameExp)
      end

      # Output statement.
      def outputs(*items)
        @outputs = items.map(&DataNameExp)
      end

      def params(*items)
        @params = items
      end

      # Content definition.
      def content(s)
        @content = s
      end

      def call(rule_path)
        Rule::FlowParts::Call.new(rule_path)
      end

      def call_with_sync(rule_path)
        Rule::FlowParts::CallWithSync.new(rule_path)
      end
    end

    # Flow rule definition.
    class FlowDefinition < Definition
      def to_rule(path)
        Rule::FlowRule.new(path, @inputs, @outputs, @params, @content)
      end
    end

    # Action rule definition.
    class ActionDefinition < Definition
      # Convert to a rule handler.
      def to_rule(path)
        Rule::ActionRule.new(path, @inputs, @outputs, @params, @content)
      end
    end

    def self.load(file)
      return eval(file.read).table
    end

    attr_reader :rules

    def initialize(&b)
      @rules = {}
      instance_eval(&b)
    end

    def flow(name, &b)
      flow = FlowDefinition.eval(&b).to_rule(name)
      @rules[name] = flow
    end

    def action(name, &b)
      action = ActionDefinition.eval(&b).to_rule(name)
      @rules[name] = action
    end

    def [](name)
      @rules[name]
    end
  end
end
