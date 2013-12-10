module Pione
  module Command
    # PioneTupleSpaceReceiver is a command that launchs tuple space receiver
    # agent.
    class PioneTupleSpaceReceiver < BasicCommand
      #
      # basic informations
      #

      toplevel true

      command_name "pione-tuple-space-receiver" do |cmd|
        "front: %s, parent: %s" % [Global.front.uri, cmd.option[:parent_front].uri]
      end

      command_banner(Util::Indentation.cut(<<-TXT))
        Run tuple space receiver process for receiving notification packet.
        This command is launched by other processes like pione-broker normally,
        but you can force to start by calling with --no-parent option.
      TXT

      command_front Front::TupleSpaceReceiverFront

      #
      # options
      #

      use_option :color
      use_option :debug
      use_option :communication_address
      use_option :parent_front

      define_option(:notification_port) do |item|
        item.long = "--notification-port=PORT"
        item.desc = "set notification port number"
        item.action = lambda do |_, _, port|
          Global.notification_port = port.to_i
        end
      end

      #
      # class methods
      #

      # Create a new process of tuple space provider command.
      def self.spawn
        spawner = Spawner.new("pione-tuple-space-receiver")

        # debug options
        spawner.option("--debug=system") if Global.debug_system
        spawner.option("--debug=ignored_exception") if Global.debug_ignored_exception
        spawner.option("--debug=rule_engine") if Global.debug_rule_engine
        spawner.option("--debug=communication") if Global.debug_communication
        spawner.option("--debug=notification") if Global.debug_notification

        # requisite options
        spawner.option("--parent-front", Global.front.uri)
        spawner.option("--communication-address", Global.communication_address)
        spawner.option("--notification-port", Global.notification_port.to_s)

        # optionals
        spawner.option("--color") if Global.color_enabled

        spawner.spawn
      end

      #
      # instance methods
      #

      attr_reader :tuple_space_receiver

      #
      # command lifecycle: setup phase
      #

      setup :parent_process_connection, :module => CommonCommandAction
      setup :broker

      # set my uri to parent front as its provider
      def setup_broker
        option[:parent_front].set_tuple_space_receiver(Global.front.uri)
      end

      #
      # command lifecycle: execution phase
      #

      execute :agent

      # create a tuple space receiver agent
      def execute_agent
        @agent = Agent::TupleSpaceReceiver.start(option[:parent_front])
        @agent.wait_until_terminated(nil)
      rescue Agent::ConnectionError
        Log::SystemLog.fatal("pione-tuple-space-receiver is terminated because pione-borker may be dead.")
        terminate
      end

      #
      # command lifecycle: termination phase
      #

      termination_phase :timeout => 5
      terminate :agent
      terminate :parent_process_connection, :module => CommonCommandAction

      def terminate_agent
        @agent.terminate if @agent
      end
    end
  end
end
