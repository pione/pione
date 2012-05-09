require 'innocent-white/rule'

module InnocentWhite
  module Rule
    # RootRule is a hidden toplevel rule like the following:
    #   Rule Root
    #     input-all  '*'
    #     output-all '*'.except('{$INPUT[1]}')
    #   Flow
    #     rule /Main
    #   End
    class RootRule < FlowRule

      # Make new rule.
      def initialize(rule_path)
        inputs  = [DataExpr.all("*")]
        outputs = [DataExpr.all("*").except("{$INPUT[1]}")]
        content = [FlowElement::CallRule.new(rule_path)]
        super(nil, inputs, outputs, [], content)
        @path = 'root'
        @domain = '/root'
      end

      # Make new handler object of this rule.
      def make_handler(ts_server)
        input_combinations = find_input_combinations(ts_server, "/input")
        inputs = input_combinations.first
        RootHandler.new(ts_server, self, inputs, [], {})
      end
    end

    # RootHandler is a special handler for RootRule.
    class RootHandler < FlowHandler
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

