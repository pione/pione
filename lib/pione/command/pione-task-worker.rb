module Pione
  module Command
    # This is a body for +pione-task-worker+ command.
    class PioneTaskWorker < FrontOwnerCommand
      #
      # command info
      #

      define_info do
        set_name "pione-task-worker"
        set_tail {|cmd|
          begin
            "{Front: %s, ParentFront: %s}" % [Global.front.uri, cmd.option[:parent_front].uri]
          rescue => e
            Util::ErrorReport.warn("faild to get command line options.", self, e, __FILE__, __LINE__)
          end
        }
        set_banner(Util::Indentation.cut(<<-TEXT))
          Run a task worker process. This command assumes to be launched by
          pione-client or pione-broker, so you should not execute this by hand.
        TEXT
      end

      #
      # options
      #

      define_option do
        use :color
        use :debug
        use :my_ip_address
        use :parent_front

        define(:tuple_space_id) do |item|
          item.long = '--tuple-space-id=UUID'
          item.desc = 'tuple space id that the worker joins'
          item.requisite = true
          item.value = proc {|id| id}
        end

        define(:features) do |item|
          item.long = '--features=FEATURES'
          item.desc = 'set features'
          item.value = proc do |features|
            begin
              stree = DocumentParser.new.expr.parse(features)
              opt = {package_name: "*feature*", filename: "*feature*"}
              DocumentTransformer.new.apply(stree, opt)
            rescue Parslet::ParseFailed => e
              puts "invalid parameters: " + str
              Util::ErrorReport.print(e)
              abort
            end
          end
        end

        validate do |option|
          begin
            # get the parent front server
            option[:parent_front].uuid
          rescue => e
            msg = "pione-task-worker cannot get the parent front server"
            ErrorReport.abort(msg, self, e, __FILE__, __LINE__)
          end
        end
      end

      #
      # class methods
      #

      # Create a new process of +pione-task-worker+ command.
      def self.spawn(features, tuple_space_id)
        spawner = Spawner.new("pione-task-worker")

        # requisite options
        spawner.option("--parent-front", Global.front.uri)
        spawner.option("--tuple-space-id", tuple_space_id)

        # optionals
        spawner.option("--debug") if Pione.debug_mode?
        spawner.option("--show-communication") if Global.show_communication
        spawner.option("--features", features) if features

        spawner.spawn # this method returns child front
      end

      #
      # instance methods
      #

      attr_reader :agent
      attr_reader :tuple_space_server

      def create_front
        Front::TaskWorkerFront.new(self)
      end

      prepare do
        begin
          # add child process to the parent
          option[:parent_front].add_child(Process.pid, Global.front.uri)

          # connect to tuple space
          @tuple_space_server = option[:parent_front].get_tuple_space(option[:tuple_space_id])
          unless @tuple_space_server
            abort("pione-task-worker error: no tuple space server")
          end

          # make agents
          @agent = Agent::TaskWorker.new(@tuple_space_server, option[:features])

          # get base uri
          if @tuple_space_server.base_location.kind_of?(Location::DropboxLocation)
            Location::Dropbox.init(@tuple_space_server)
            unless Location::Dropbox.ready?
            abort("You aren't ready to access Dropbox.")
            end
          end
        rescue => e
          msg = "Exception raised in preparing pione-task-worker, go termination process."
          Util::ErrorReport.error(msg, self, e, __FILE__, __LINE__)
          call_terminations
        end
      end

      start do
        # start task worker activity
        @agent.start

        # wait agent termination
        Util.ignore_exception(DRb::DRbConnError, DRb::ReplyReaderThreadError) do
          @agent.wait_until_terminated(nil)
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
                  break if @agent.terminated?
                  sleep 1
                end
              end
            end

            # disconnect parent front
            option[:parent_front].remove_task_worker(self, option[:connection_id])

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
