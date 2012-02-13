require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class ProcessManager < Base
      class ProcessManagerStatus < AgentStatus
        #define_sub_state :initialized, :module_loading
        #define_sub_state :initialized, :
      end

      set_status_class ProcessManagerStatus
      set_agent_type :process_manager

      attr_reader :document

      def initialize(ts_server, document)
        super(ts_server)
        @document = document
        load_document(document)
        @output_threads = []
        start_running
      end

      def load_document(document)
        document.each do |path, mod|
          @tuple_space_server.write(Tuple[:module].new(path: path, content: mod))
        end
      end

      def run
        main = @document["/main"]
        if inputs = main.catch_inputs(@tuple_space_server, "/")
          outputs = main.new(inputs).outputs
          params = []
          @tuple_space_server.write(Tuple[:task].new(name: "/main",
                                                     inputs: inputs,
                                                     outputs: outputs,
                                                     params: params,
                                                     task_id: Util.uuid))
          outputs.each do |name|
            @output_threads << Thread.new do
              @tuple_space_server.read(Tuple[:data].new(name: name,
                                                        path: "/"))
            end
          end
        else
          sleep 0.1
          stop if finished?
        end
      end

      def finished?
        @output_threads.map {|thread| thread.alive?}.uniq == [false]
      end
    end

    set_agent ProcessManager
  end
end
