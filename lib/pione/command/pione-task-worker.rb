module Pione
  module Command
    # This is a class for +pione-task-worker+ command. +pione-task-worker+
    # starts a task worker agent with tuple space server.
    class PioneTaskWorker < ChildProcess
      set_program_name("pione-task-worker") do
        parent_front = @no_parent_mode ? "nil" : @parent_front.uri
        "<front=%s, parent-front=%s>" % [Global.front.uri, parent_front]
      end

      set_program_message <<TXT
Runs task worker process. This command is launched by other processes like
pione-client or pione-broker.
TXT

      use_option_module CommandOption::ChildProcessOption

      # --connection-id
      define_option('--connection-id=ID', 'set connection id') do |id|
        @connection_id = id
      end

      attr_reader :connection_id
      attr_reader :agent
      attr_reader :tuple_space_server

      private

      def create_front
        Pione::Front::TaskWorkerFront.new(self)
      end

      def validate_options
        super

        # check requisite options
        if @connection_id.nil?
          abort("error: no connection id")
        end

        # get the parent front server
        begin
          @parent_front.uuid
        rescue => e
          abort("pione-task-worker cannot get the parent front server: %s" % e)
        end
      end

      def prepare
        super

        @tuple_space_server = @parent_front.get_tuple_space_server(@connection_id)
        @agent = Pione::Agent[:task_worker].new(@tuple_space_server)

        # connect caller front
        @parent_front.add_task_worker_front(Global.front, @connection_id)

        # get base uri
        if @tuple_space_server.base_uri.scheme == "dropbox"
          Resource::Dropbox.init(@tuple_space_server)
          unless Resource::Dropbox.ready?
            abort("You aren't ready to access Dropbox.")
          end
        end
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
        rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
          terminate
        end
      end

      def terminate
        return if @terminated
        @agent.terminate

        while true
          break if @agent.terminated? and @agent.running_thread.stop?
          sleep 1
        end

        # disconnect parent front
        @parent_front.remove_task_worker_front(self, @connection_id)

        # flag
        @terminated = true

        super
      rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
        abort
      end
    end
  end
end
