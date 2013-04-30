module Pione
  module RuleHandler
    class EmptyHandler < BasicHandler
      def self.message_name
        "Empty"
      end

      def execute
        find_outputs
        return @outputs
      end
    end
  end
end
