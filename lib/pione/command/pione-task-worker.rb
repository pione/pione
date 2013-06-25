module Pione
  module Command
    # This is a class for +pione-task-worker+ command. +pione-task-worker+
    # starts a task worker agent with tuple space server.
    class PioneTaskWorker < ChildProcess
      define_info do
        set_name "pione-task-worker"
        set_tail {|cmd|
          begin
            "{Front: %s, ParentFront: %s}" % [
              Global.front.uri, cmd.option[:no_parent_mode] ? "nil" : cmd.option[:parent_front].uri
            ]
          rescue => e
            Util::ErrorReport.warn("faild to get command line options.", self, e, __FILE__, __LINE__)
          end
        }
        set_banner <<BANNER
Run task worker process. This command is launched by other processes like
pione-client or pione-broker.
BANNER
      end

      define_option do
        use :color
        use :debug
        use :my_ip_address
        use :no_parent
        use :parent_front

        define(:connection_id) do |item|
          item.long = '--connection-id=ID'
          item.desc = 'set connection id'
          item.value = proc {|id| id}
        end

        define(:features) do |item|
          item.long = '--features=FEATURES'
          item.desc = 'set features'
          item.value = proc do |features|
            begin
              DocumentTransformer.new.apply(
                DocumentParser.new.feature_expr.parse(features)
              )
            rescue Parslet::ParseFailed => e
              puts "invalid parameters: " + str
              Util::ErrorReport.print(e)
              abort
            end
          end
        end

        validate do |option|
          # check requisite options
          abort("error: no connection id") if option[:connection_id].nil?

          # get the parent front server
          begin
            option[:parent_front].uuid
          rescue => e
            if Pione.debug_mode?
              debug_message "pione-task-worker cannot get the parent front server: %s" % e
            end
            abort
          end
        end
      end

      attr_reader :agent
      attr_reader :tuple_space_server

      private

      def create_front
        Pione::Front::TaskWorkerFront.new(self)
      end

      prepare do
        begin
          @tuple_space_server = option[:parent_front].get_tuple_space_server(option[:connection_id])
          @agent = Pione::Agent[:task_worker].new(@tuple_space_server, option[:features])
          @command_listener = Pione::Agent[:command_listener].new(@tuple_space_server, self)

          # connect caller front
          option[:parent_front].add_task_worker_front(Global.front, option[:connection_id])

          abort("pione-task-worker error: no tuple space server") unless @tuple_space_server

          # get base uri
          if @tuple_space_server.base_location.kind_of?(Location::DropboxLocation)
            Location::Dropbox.init(@tuple_space_server)
            unless Location::Dropbox.ready?
            abort("You aren't ready to access Dropbox.")
            end
          end
        rescue => e
          msg = "Exception raised in preparing task-worker, go termination process."
          Util::ErrorReport.warn(msg, self, e, __FILE__, __LINE__)
          call_terminations
        end
      end

      start do
        # start task worker activity
        @agent.start
        @command_listener.start

        # wait...
        begin
          @agent.running_thread.join
        rescue DRb::DRbConnError, DRb::ReplyReaderThreadError
          # ignore
        end
      end

      terminate do
        Global.monitor.synchronize do
          begin
            # flag
            return if @terminated
            @terminated = true

            # terminate the agent
            if @agent
              @agent.terminate

              Timeout.timeout(5) do
                while true
                  break if @agent.terminated? and @agent.running_thread and @agent.running_thread.stop?
                  sleep 1
                end
              end
            end

            # disconnect parent front
            option[:parent_front].remove_task_worker_front(self, option[:connection_id])

          rescue DRb::DRbConnError, DRb::ReplyReaderThreadError => e
            Util::ErrorReport.warn("Disconnected in termination process of task worker agent.", self, e, __FILE__, __LINE__)
          rescue ThreadError => e
            # tuple space may be closed
            Util::ErrorReport.warn("Failed in termination process of task worker agent.", self, e, __FILE__, __LINE__)
          rescue Timeout::Error => e
            Util::ErrorReport.warn("Timeouted in termination of pione-task-worker.", self, e, __FILE__, __LINE__)
          end
        end
      end
    end
  end
end
