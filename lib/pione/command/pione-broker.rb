module Pione
  module Command
    # PioneBroker is a command that starts activity of broker agent. This
    # command will spawn +pione-task-worker+ and +pione-tuple-space-receiver+
    # commands.
    class PioneBroker < BasicCommand
      #
      # basic informations
      #

      command_name("pione-broker") do |cmd|
        "front: %s, task_worker: %s" % [Global.front.uri, cmd.option[:task_worker]]
      end
      command_banner "Run broker agent to launch task workers."
      command_front Front::BrokerFront

      #
      # options
      #

      use_option :color
      use_option :daemon
      use_option :debug
      use_option :features
      use_option :my_ip_address
      use_option :task_worker

      validate_option do |option|
        unless option[:task_worker] > 0
          abort("error: no task worker resources")
        end
      end

      #
      # instance method
      #

      attr_reader :agent

      #
      # command lifecycle: setup phase
      #

      setup_phase :timeout => 10
      setup :agent
      setup :tuple_space_receiver

      # Create a broker agent.
      def setup_agent
        @agent = Agent::Broker.new(task_worker_resource: option[:task_worker])
      end

      # Spawn a pione-tuple-space-receiver process.
      def setup_tuple_space_receiver
        spawner = PioneTupleSpaceReceiver.spawn
        spawner.when_terminated do
          unless termination?
            abort("%s is terminated because child tuple space receiver is dead." % command_name)
          end
        end
        @tuple_space_receiver = spawner.child_front
      rescue SpawnError =>e
        abort(e.message)
      end

      #
      # command lifecycle: action phase
      #

      execute :start_banner
      execute :agent

      # Declare pione-broker start.
      def execute_start_banner
        Log::SystemLog.info "pione-broker starts the activity (#%s)" % Process.pid
      end

      # Start broker agent activity and wait it to be terminated.
      def execute_agent
        @agent.start
        @agent.wait_until_terminated(nil)
      end

      #
      # command lifecycle: termination phase
      #

      termination_phase :timeout => 15
      terminate :child_process, :module => CommonCommandAction
      terminate :agent
      terminate :end_banner

      # Terminate broker agent.
      def terminate_agent
        @agent.terminate if @agent and not(@agent.terminated?)
      end

      # Declare pione-broker end.
      def terminate_end_banner
        Log::SystemLog.info "pione-broker ends the activity (status: %s, #%s)" % [Global.exit_status, Process.pid]
      end
    end
  end
end
