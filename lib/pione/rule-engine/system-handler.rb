module Pione
  module RuleEngine
    class SystemHandler < BasicHandler
      def self.message_name
        "System"
      end

      def execute
        @rule.body.call(tuple_space_server)
      end
    end
  end
end
