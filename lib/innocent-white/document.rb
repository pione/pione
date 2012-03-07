require 'innocent-white/common'
require 'innocent-white/data-name-exp'
require 'innocent-white/rule'

module InnocentWhite
  class Document < InnocentWhiteObject
    class Definition
      # Evaluate the block in a rule definition context.
      def self.eval(&b)
        obj = new
        obj.instance_eval(&b)
        return obj
      end

      # Create all modified name.
      def all(name)
        DataNameExp.all(name)
      end

      # Create each modified name.
      def each(name)
        DataNameExp.each(name)
      end

      # Create stdout data name.
      def stdout(name)
        DataNameExp.stdout(name)
      end

      # Create stderr data name.
      def stderr(name)
        DataNameExp.stderr(name)
      end

      # Input statement.
      def inputs(*items)
        @inputs = items.map(&DataNameExp)
      end

      # Output statement.
      def outputs(*items)
        @outputs = items.map(&DataNameExp)
      end

      # Parameter statement.
      def params(*items)
        @params = items
      end

      # Content definition.
      def content(s)
        @content = s
      end

      # Create a rule caller.
      def call(rule_path)
        Rule::FlowParts::Call.new(rule_path)
      end

      # Add ruby shebang line.
      def ruby(str, charset=nil)
        res = "#!/usr/bin/env ruby\n"
        res << "# -*- coding: #{charset} -*-\n" if charset
        return res + str
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

    # Load a document and return rule table.
    def self.load(file)
      return eval(file.read)
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
