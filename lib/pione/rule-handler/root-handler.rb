module Pione
  module RuleHandler
    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
      # :nodoc:
      def execute
        puts ">>> Start Root Rule Execution" if debug_mode?
        # import inputs from input domain
        copy_data_into_domain(@inputs.flatten, @domain)
        # handling
        result = super
        # export outputs to output domain
        copy_data_into_domain(@outputs.flatten, '/output')
        # sync_output
        puts ">>> End Root Rule Execution" if debug_mode?
        return result
      end
    end
  end
end

