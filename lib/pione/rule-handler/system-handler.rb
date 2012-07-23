require 'pione/common'

module Pione
  module RuleHandler
    class SystemHandler < BaseHandler
      def execute
        @rule.body.call(tuple_space_server)
      end
    end
  end
end
