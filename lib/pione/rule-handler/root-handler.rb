module Pione
  module RuleHandler
    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
      # :nodoc:
      def execute
        user_message ">>> Start Root Rule Execution: %s" % [handler_digest]
        # import inputs from input domain
        copy_data_into_domain(@inputs.flatten, @domain)
        # handling
        result = super
        # export outputs to output domain
        copy_data_into_domain(@outputs.flatten, '/output')
        # sync_output
        user_message "<<< End Root Rule Execution: %s" % [handler_digest]
        return result
      end
    end
  end
end

