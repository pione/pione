module Pione
  module RuleEngine
    # Exception class for rule execution failure.
    class RuleExecutionError < StandardError
      def initialize(handler)
        @rule_name = handler.rule_name
        @inputs = handler.inputs
        @outputs = handler.outputs
        @params = handler.param_set
        @package_id = handler.package_id
      end

      def message
        "Execution error when handling the rule '%s': inputs=%s, output=%s, param_set=%s" % [
          @rule_name,
          @inputs,
          @outputs,
          @param_set
        ]
      end
    end

    class ActionError < RuleExecutionError
      def initialize(handler, digest, report)
        super(handler)
        @digest = digest
        @report = report
      end

      def message
        "Action rule %s has errored:\n%s" % [@digest, @report]
      end
    end

    class InvalidOutputError < RuleExecutionError
      def initialize(handler, outputs)
        super(handler)
        @outputs = outputs
      end

      def message
        args = [@rule_name, @package_id, @outputs]
        "Outputs of rule '%s' in package &%s are invalid: %s" % args
      end
    end

    class UnknownRule < RuleExecutionError; end
  end
end
