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

      # --feature
      define_option('--features="FEATURES"', 'set features') do |features|
        begin
          features = DocumentTransformer.new.apply(
            DocumentParser.new.feature_expr.parse(features)
          )
          @features = features
        rescue Parslet::ParseFailed => e
          puts "invalid parameters: " + str
          Util::ErrorReport.print(e)
          abort
        end
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
          if Pione.debug_mode?
            debug_message "pione-task-worker cannot get the parent front server: %s" % e
          end
          abort
        end
      end

      def prepare
        super

        @tuple_space_server = @parent_front.get_tuple_space_server(@connection_id)
        @features = Model::Feature::EmptyFeature.new unless @features
        @agent = Pione::Agent[:task_worker].new(@tuple_space_server, @features)
        @command_listener = Pione::Agent[:command_listener].new(@tuple_space_server, self)

        # connect caller front
        @parent_front.add_task_worker_front(Global.front, @connection_id)

        abort("pione-task-worker error: no tuple space server") unless @tuple_space_server

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
        @command_listener.start

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
