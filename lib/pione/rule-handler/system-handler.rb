require 'pione/common'

module Pione
  module RuleHandler
    class SystemHandler < BaseHandler
      def self.message_name
        "System"
      end

      def execute
        @rule.body.call(tuple_space_server)
      end
    end
  end
end
