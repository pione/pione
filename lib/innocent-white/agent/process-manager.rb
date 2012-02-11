module InnocentWhite
  module Agent
    class ProcessManager < Base
      attr_reader :document

      def initialize(document)
        super()
        @document = document
      end

      def run(ts_server)
        Thread.new do
          loop do
            # dummy
          end
        end
      end
    end
  end

  Agent[:process_manager] = ProcessManager
end
