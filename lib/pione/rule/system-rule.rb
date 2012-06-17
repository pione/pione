require 'pione/common'

module Pione
  module Rule
    # SystemRule represents built-in rule definition.
    class SystemRule < ActionRule
      def initialize(path, &b)
        inputs = [Model::DataExpr.new('*')]
        outputs = []
        params = []
        features = []
        super(path, inputs, outputs, params, features, b)
      end

      # Return SystemHandler class.
      def handler_class
        SystemHandler
      end
    end

    class SystemHandler < BaseHandler
      def execute
        @rule.content.call(tuple_space_server)
      end
    end

    SYSTEM_TERMINATE = SystemRule.new('/System/Terminate') do |tuple_space_server|
      user_message "!!!!!!!!!!!!!!!!!"
      user_message "!!! Terminate !!!"
      user_message "!!!!!!!!!!!!!!!!!"
      tuple_space_server.write(Tuple[:command].new("terminate"))
    end

    SYSTEM_RULES = [ SYSTEM_TERMINATE ]
  end
end
