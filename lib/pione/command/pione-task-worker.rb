module Pione
  module Command
    # This is a body for +pione-task-worker+ command.
    class PioneTaskWorker < BasicCommand
      #
      # basic informations
      #

      command_name "pione-task-worker" do |cmd|
        "front: %s, parent: %s" % [Global.front.uri, cmd.option[:parent_front].uri]
      end

      command_banner(Util::Indentation.cut(<<-TEXT))
        Run a task worker process. This command assumes to be launched by
        pione-client or pione-broker, so you should not execute this by hand.
      TEXT

      command_front Front::TaskWorkerFront

      #
      # options
      #

      use_option :color
      use_option :debug
      use_option :my_ip_address
      use_option :parent_front
      use_option :features

      define_option(:tuple_space_id) do |item|
        item.long = '--tuple-space-id=UUID'
        item.desc = 'tuple space id that the worker joins'
        item.requisite = true
        item.value = proc {|id| id}
      end

      #
      # class methods
      #

      # Create a new process of +pione-task-worker+ command.
      def self.spawn(features, tuple_space_id)
        spawner = Spawner.new("pione-task-worker")

        # debug options
        spawner.option("--debug=system") if Global.debug_system
        spawner.option("--debug=ignored_exception") if Global.debug_ignored_exception
        spawner.option("--debug=rule_engine") if Global.debug_rule_engine
        spawner.option("--debug=communication") if Global.debug_communication
        spawner.option("--debug=presence_notification") if Global.debug_presence_notification

        # requisite options
        spawner.option("--parent-front", Global.front.uri)
        spawner.option("--tuple-space-id", tuple_space_id)
        spawner.option("--features", features) if features

        # optionals
        spawner.option("--color") if Global.color_enabled

        spawner.spawn # this method returns child front
      end

      #
      # instance methods
      #

      attr_reader :agent
      attr_reader :tuple_space_server

      #
      # command lifecycle: setup phase
      #

      setup_phase :timeout => 15
      setup :parent_process_connection, :module => CommonCommandAction
      setup :tuple_space
      setup :agent
      setup :base_location
      setup :job_terminator

      # Get tuple space from parent process and test the connection.
      def setup_tuple_space
        @tuple_space = option[:parent_front].get_tuple_space(option[:tuple_space_id])

        unless @tuple_space
          abort("%s cannot get tuple space \"%s\"." % [command_name, option[:tuple_space_id]])
        end

        if Util.error?(:timeout => 3) {@tuple_space.uuid}
          abort("%s cannot connect to tuple space." % command_name)
        end
      end

      # Create a task worker agent.
      def setup_agent
        @agent = Agent::TaskWorker.new(@tuple_space, option[:expressive_features])
      rescue Agent::TupleSpaceError => e
        abort(e.message)
      end

      # Setup base location.
      def setup_base_location
        if @tuple_space.base_location.kind_of?(Location::DropboxLocation)
          Location::Dropbox.init(@tuple_space)
          unless Location::Dropbox.ready?
            abort("You aren't ready to access Dropbox.")
          end
        end
      end

      # Create a job terminator and setup the action.
      def setup_job_terminator
        @job_terminator = Agent::JobTerminator.new(@tuple_space) do |status|
          if status.error?
            abort("pione-task-worker catched the error: %s" % status.exception.message)
          else
            terminate
          end
        end
      end

      #
      # command lifecycle: execution phase
      #

      handle_execution_exception(DRb::DRbConnError) do |cmd, e|
        Log::Debug.system do
          "%s goes termination phase because the exception was catched: %s" % [cmd.command_name, e.message]
        end
        cmd.terminate
      end
      execute :job_terminator
      execute :agent

      # Start the job terminator.
      def execute_job_terminator
        @job_terminator.start
      end

      # Start task worker activity and wait the termination.
      def execute_agent
        @agent.start
        @agent.wait_until_terminated(nil)
      end

      #
      # command lifecycle: termination phase
      #

      termination_phase :timeout => 10
      terminate :job_terminator
      terminate :agent
      terminate :parent_process_connection, :module => CommonCommandAction

      # Terminate job terminator.
      def terminate_job_terminator
        if @job_terminator and not(@job_terminator.terminated?)
          @job_terminator.terminate
        end
      end

      # Terminate task worker agent.
      def terminate_agent
        if @agent
          @agent.terminate
          @agent.wait_until_terminated(nil)
        end
      end
    end
  end
end

