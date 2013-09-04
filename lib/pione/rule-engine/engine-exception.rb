module Pione
  module RuleEngine
    # Exception class for rule execution failure.
    class RuleExecutionError < StandardError
      def initialize(handler)
        @handler = handler
      end

      def message
        "Execution error when handling the rule '%s': inputs=%s, output=%s, params=%s" % [
          @handler.rule.path,
          @handler.inputs,
          @handler.outputs,
          @handler.params.inspect
        ]
      end
    end

    class InvalidOutputError < RuleExecutionError
      def initialize(handler, outputs)
        super(handler)
        @outputs = outputs
      end

      def message
        args = [@handler.rule_name, @handler.package_id, @outputs]
        "Outputs of rule '%s' in package &%s are invalid: %s" % args
      end
    end

    class UnknownRule < StandardError; end
  end
end
