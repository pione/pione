require 'innocent-white/common'

module InnocentWhite
  module Rule
    class CommandRule < ActionRule
      def initialize(path, &b)
        inputs = [DataExpr.new('*')]
        outputs = []
        params = []
        super(path, inputs, outputs, params, b)
      end

      # Make rule handler from the rule.
      def make_handler(ts_server, inputs, params, opts={})
        CommandHandler.new(ts_server, self, inputs, params, opts)
      end
    end

    class CommandHandler < BaseHandler
      def execute
        @rule.content.call(tuple_space_server)
      end
    end

    COMMAND_TERMINATE = CommandRule.new('/Command/Terminate') do |tuple_space_server|
      user_message "!!!!!!!!!!!!!!!!!"
      user_message "!!! Terminate !!!"
      user_message "!!!!!!!!!!!!!!!!!"
      tuple_space_server.write(Tuple[:command].new("terminate"))
    end

    COMMAND_RULES = [ COMMAND_TERMINATE ]
  end
end
