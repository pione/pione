module Pione
  module Command
    # PioneTupleSpaceProvider is for +pione-tuple-space-provider+ command.
    class PioneTupleSpaceProvider < BasicCommand
      #
      # command info
      #

      toplevel true

      command_name "pione-tuple-space-provider" do |cmd|
        "front: %s, parent: %s" % [Global.front.uri, cmd.option[:parent_front].uri]
      end

      command_banner(Util::Indentation.cut(<<-TXT))
        Run tuple space provider process for sending tuple space presence
        notifier. This command assumes to be launched by other processes like
        pione-client or pione-relay.
      TXT

      command_front Pione::Front::TupleSpaceProviderFront do |cmd|
        [cmd.option[:parent_front].get_tuple_space(nil)]
      end

      #
      # options
      #

      use_option :color
      use_option :debug
      use_option :communication_address
      use_option :parent_front
      use_option :presence_notification_address

      #
      # class methods
      #

      # Create a new process of tuple space provider command.
      def self.spawn
        spawner = Spawner.new(command_name)

        # debug options
        spawner.option("--debug=system") if Global.debug_system
        spawner.option("--debug=ignored_exception") if Global.debug_ignored_exception
        spawner.option("--debug=rule_engine") if Global.debug_rule_engine
        spawner.option("--debug=communication") if Global.debug_communication
        spawner.option("--debug=presence_notification") if Global.debug_presence_notification

        # requisite options
        spawner.option("--parent-front", Global.front.uri)
        spawner.option("--communication-address", Global.communication_address)
        Global.presence_notification_addresses.each do |address|
          spawner.option("--presence-notification-address", address.to_s)
        end

        # optionals
        spawner.option("--color") if Global.color_enabled

        spawner.spawn
      end

      #
      # instance methods
      #

      attr_reader :agent

      #
      # command lifecycle: setup phase
      #

      setup_phase :timeout => 5
      setup :parent_process_connection, :module => CommonCommandAction

      #
      # command lifecycle: execution phase
      #

      execute :agent

      # Start agent activity and wait the termination.
      def execute_agent
        @agent = Agent::TupleSpaceProvider.start(Global.front)
        @agent.wait_until_terminated(nil)
      end

      #
      # command lifecycle: termination phase
      #

      termination_phase :timeout => 5
      terminate :agent
      terminate :parent_process_connection, :module => CommonCommandAction

      # Terminate agent.
      def terminate_agent
        if @agent and not(@agent.terminated?)
          @agent.terminate
          @agent.wait_until_terminated(nil)
        end
      end
    end
  end
end
