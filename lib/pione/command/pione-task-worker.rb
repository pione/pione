module Pione
  module Command
    # This is a class for +pione-task-worker+ command. +pione-task-worker+
    # starts a task worker agent with tuple space server.
    class PioneTaskWorker < ChildProcess
      set_program_name("pione-task-worker") do
        "--caller-front %s --connection-id %s" % [@caller_front.uri, @connection_id]
      end

      define_option('--connection-id id') do |id|
        @connection_id = id
      end

      attr_reader :connection_id
      attr_reader :agent
      attr_reader :tuple_space_server

      private

      def create_front
        Pione::Front::TaskWorkerFront.new(self, nil)
      end

      def validate_options
        super

        # check requisite options
        abort("error: no connection id") if @connection_id.nil?

        # get the caller front server
        begin
          @caller_front.uuid
        rescue => e
          abort("pione-task-worker cannot get the caller front server: %s" % e)
        end
      end

      def prepare
        super

        @tuple_space_server = @caller_front.get_tuple_space_server(@connection_id)
        @agent = Pione::Agent[:task_worker].new(@tuple_space_server)

        # connect caller front
        @caller_front.add_task_worker_front(self, @connection_id)
      end

      def start
        super

        # start task worker activity
        @agent.start

        # wait...
        begin
          @agent.running_thread.join
          # terminate
          terminate
        rescue DRb::DRbConnError
          # do nothing
        end
      end

      def terminate
        return if @terminated
        @agent.terminate

        while true
          break if @agent.terminated? and @agent.running_thread.stop?
          sleep 0.1
        end

        # disconnect caller front
        @caller_front.remove_task_worker_front(self, @connection_id)
        @terminated = true

        super
      end
    end
  end
end
