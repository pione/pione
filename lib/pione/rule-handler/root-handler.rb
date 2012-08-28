module Pione
  module RuleHandler
    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
      def self.message_name
        "Root"
      end

      # :nodoc:
      def execute
        # import inputs from input domain
        copy_data_into_domain(@inputs.flatten, @domain)
        # handling
        result = super
        # export outputs to output domain
        copy_data_into_domain(@outputs.flatten, '/output')

        return result
      end
    end
  end
end

