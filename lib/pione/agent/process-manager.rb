module Pione
  module Agent
    class ProcessManager < BasicAgent
      set_agent_type :process_manager

      attr_reader :document

      def initialize(ts_server, document, params)
        super()
        raise ArgumentError unless document.main
        @document = document
        @params = params
        @output_threads = []
        # start_running
        run
      end

      def run
        while true do
          if handler = @document.root_rule(@params).make_handler($tuple_space_server)
            handler.handle
          else
            user_message "no inputs"
          end

          break unless option.stream
          sleep 5
          user_message "check new inputs"
        end
      end
    end

    set_agent ProcessManager
  end
end
