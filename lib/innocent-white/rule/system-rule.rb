require 'innocent-white/common'

module InnocentWhite
  module Rule
    class SystemRule < ActionRule
      def initialize(path, &b)
        inputs = [DataExpr.new('*')]
        outputs = []
        params = []
        super(path, inputs, outputs, params, b)
      end

      # Make rule handler from the rule.
      def make_handler(ts_server, inputs, params, opts={})
        SystemHandler.new(ts_server, self, inputs, params, opts)
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
