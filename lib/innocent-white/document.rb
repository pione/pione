require 'innocent-white/innocent-white-object'
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
      def inputs(items)
        @inputs = items.map(&Rule::DataNameExp)
      end

      # Output statement.
      def outputs(items)
        @outputs = items.map(&Rule::DataNameExp)
      end

      def params(items)
        @params = items
      end

      # Content definition.
      def content(s)
        @content = s
      end
    end

    # Flow rule definition.
    class FlowDefinition
      def to_rule
        Rule::FlowRule.new(@inputs, @outputs, @params, @content)
      end
    end

    # Action rule definition.
    class ActionDefinition
      # Convert to a rule handler.
      def to_rule
        Rule::ActionRule.new(@inputs, @outputs, @params, @content)
      end
    end

    def self.load(file)
      
      return eval(file.read).table
    end

    attr_reader :table

    def initialize(&b)
      @table = {}
      instance_eval(&b)
    end

    def define_flow(name, &b)
      flow = FlowDefinition.eval(&b).to_rule
      @table[name] = flow
    end

    def define_action(name, &b)
      action = ActionDefinition.eval(&b).to_rule
      @table[name] = action
    end
  end
end
