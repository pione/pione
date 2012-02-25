require 'innocent-white/common'
require 'innocent-white/agent'
require 'innocent-white/rule'

module InnocentWhite
  module Agent
    class RuleProvider < Base
      set_agent_type :rule_provider

      def initialize(ts_server)
        super(ts_server)
        @table = {}
      end

      define_state :initialized
      define_state :request_waiting
      define_state :rule_loading
      define_state :terminated

      define_state_transition :initialized => :request_waiting
      define_state_transition :request_waiting => :rule_loading
      define_state_transition :rule_loading => :request_waiting
      define_exception_handler :error

      def transit_to_initialized
        # do nothing
      end

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

      # State error.
      # StopIteration exception means the input generation was completed.
      def transit_to_error(e)
        notify_exception(e)
        terminate
      end

      # State terminated.
      def transit_to_terminated
        Util.ignore_exception { bye }
      end

      def read(doc)
        doc.rules.each do |rule_path, rule|
          add_rule(rule_path, rule)
        end
      end

      def add_rule(rule_path, content)
        raise ArgumentError unless content.kind_of?(Rule::BaseRule)
        @table[rule_path] = content
      end

      # Return known rule pathes.
      def known_rules
        @table.keys
      end

      private

      def known_rule?(rule_path)
        @table.has_key?(rule_path)
      end
    end

    set_agent RuleProvider
  end
end
