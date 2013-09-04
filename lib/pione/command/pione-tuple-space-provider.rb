module Pione
  module Command
    # PioneTupleSpaceProvider is for +pione-tuple-space-provider+ command.
    class PioneTupleSpaceProvider < FrontOwnerCommand

      #
      # process handler
      #

      # Create a new process of tuple space provider command.
      def self.spawn
        spawner = Spawner.new(info.name)

        # requisite options
        spawner.option("--parent-front", Global.front.uri)
        spawner.option("--my-ip-address", Global.my_ip_address)
        Global.presence_notification_addresses.each do |address|
          spawner.option("--presence-notification-address", address.to_s)
        end

        # optionals
        spawner.option("--debug") if Pione.debug_mode?
        spawner.option("--show-communication") if Global.show_communication
        spawner.option("--show-presence-notifier") if Global.show_presence_notifier

        spawner.spawn
      end

      #
      # command info
      #

      define_info do
        set_name "pione-tuple-space-provider"
        set_tail {|cmd|
          "front: %s, parent: %s" % [Global.front.uri, cmd.option[:parent_front].uri]
        }
        set_banner(Util::Indentation.cut(<<-TXT))
           Run tuple space provider process for sending tuple space presence
           notifier. This command assumes to be launched by other processes like
           pione-client or pione-relay.
        TXT
      end

      #
      # options
      #

      define_option do
        use :debug
        use :color
        use :my_ip_address
        use :parent_front
        use :presence_notification_address
        use :show_communication
        use :show_presence_notifier
      end

      attr_reader :agent

      def create_front
        Pione::Front::TupleSpaceProviderFront.new(self, option[:parent_front].get_tuple_space(nil))
      end

      start do
        # start provider activity
        @agent = Agent::TupleSpaceProvider.start(Global.front)

        # add child process to the parent
        option[:parent_front].add_child(Process.pid, Global.front.uri)

        # wait agent activity
        @agent.wait_until_terminated(nil)
      end

      terminate do
        Global.monitor.synchronize do
          @agent.terminate unless @agent.terminated?
        end
      end
    end
  end
end
