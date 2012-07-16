require 'pione/common'

module Pione
  module Rule
    class SystemHandler < BaseHandler
      def execute
        @rule.body.call(tuple_space_server)
      end
    end

    SYSTEM_TERMINATE = Model::SystemRule.new('/System/Terminate') do |tuple_space_server|
      user_message "!!!!!!!!!!!!!!!!!"
      user_message "!!! Terminate !!!"
      user_message "!!!!!!!!!!!!!!!!!"
      tuple_space_server.write(Tuple[:command].new("terminate"))
    end

    SYSTEM_RULES = [ SYSTEM_TERMINATE ]
  end
end
