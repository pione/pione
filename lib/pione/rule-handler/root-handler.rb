module Pione
  module RuleHandler
    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
      def self.message_name
        "Root"
      end

      # @api private
      def execute
        # import initial input tuples from input domain
        copy_data_into_domain(@inputs.flatten, @domain)
        # execute the rule
        result = super
        # export outputs to output domain
        copy_data_into_domain(@outputs.flatten, '/output')

        return result
      end
    end
  end
end

