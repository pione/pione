module Pione
  module RuleEngine
    class EmptyHandler < BasicHandler
      def self.message_name
        "Empty"
      end

      def execute
        return find_outputs_from_space
      end
    end
  end
end
