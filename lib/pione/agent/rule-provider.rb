module Pione
  module Agent
    class RuleProvider < TupleSpaceClient

      set_agent_type :rule_provider

      def initialize(ts_server)
        super(ts_server)
        @table = {}

        # import system rules
        Model::SYSTEM_RULES.each do |command_rule|
          @table[command_rule.rule_path] = command_rule
        end
      end

      def read_document(doc)
        doc.rules.each do |rule_path, rule|
          add_rule(rule_path, rule)
        end
      end

      def add_rule(rule_path, content)
        raise ArgumentError unless content.kind_of?(Rule)
        @table[rule_path] = content
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
        out = Tuple[:rule].new(rule_path: request.rule_path)
        if known_rule?(request.rule_path)
          out.status = :known
          out.content = @table[request.rule_path]
        else
          out.status = :unknown
        end
        write(out)
      end

      def known_rule?(rule_path)
        @table.has_key?(rule_path)
      end
    end

    set_agent RuleProvider
  end
end
