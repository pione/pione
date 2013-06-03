module Pione
  module Agent
    # RuleProvider is an agent for providing rules to other agents.
    class RuleProvider < TupleSpaceClient
      set_agent_type :rule_provider

      def initialize(tuple_space_server)
        super(tuple_space_server)
        @table = {}

        # import system rules
        Component::SYSTEM_RULES.each do |command_rule|
          @table[command_rule.path] = command_rule
        end
      end

      # Read rules from the document or the package.
      #
      # @param document [Component::Document,Component::Package]
      #   document or package
      # @return [void]
      def read_rules(document)
        document.rules.each {|rule| @table[rule.path] = rule}
      end

      # Return known rule pathes.
      def known_rules
        @table.keys
      end

      define_state :request_waiting
      define_state :rule_loading

      define_state_transition :initialized => :request_waiting
      define_state_transition :request_waiting => :rule_loading
      define_state_transition :rule_loading => :request_waiting

      private

      def transit_to_request_waiting
        return take(Tuple[:request_rule].any)
      end

      def transit_to_rule_loading(request)
        if known_rule?(request.rule_path)
          write(Tuple[:rule].new(rule_path: request.rule_path, content: @table[request.rule_path]))
        else
          processing_error("rule '%s' is unknonw" % request.rule_path)
        end
      end

      def known_rule?(rule_path)
        @table.has_key?(rule_path)
      end
    end

    set_agent RuleProvider
  end
end
