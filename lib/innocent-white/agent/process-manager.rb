require 'innocent-white/agent'

module InnocentWhite
  module Agent
    class ProcessManager < Base
      set_agent_type :process_manager

      attr_reader :document

      def initialize(ts_server, document)
        super(ts_server)
        raise ArgumentError unless document.has_key?("/main")
        @document = document
        load_document(document)
        @output_threads = []
        @results = []
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
          task = Tuple[:task].new(name: "/main",
                                  inputs: inputs,
                                  outputs: outputs,
                                  params: params,
                                  task_id: Util.uuid)
          @tuple_space_server.write(task)

          # confirm outputs
          outputs.each do |name|
            @output_threads << Thread.new do
              data = Tuple[:data].new(name: name)
              @results << @tuple_space_server.read(data).to_tuple
            end
          end
        else
          sleep 0.1
          if finished?
            stop
            log(:info, "The process is finished.")
            @results.each do |result|
              log(:info, "#{result.name}:#{result.raw}")
            end
          end
        end
      end

      def finished?
        @output_threads.map{|thread| thread.alive?}.uniq == [false]
      end
    end

    set_agent ProcessManager
  end
end
