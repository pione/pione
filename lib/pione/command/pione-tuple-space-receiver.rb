module Pione
  module Command
    # PioneTupleSpaceReceiver is a command that launchs tuple space receiver
    # agent.
    class PioneTupleSpaceReceiver < FrontOwnerCommand

      #
      # process handler
      #

      # Create a new process of tuple space provider command.
      def self.spawn
        spawner = Spawner.new(info.name)

        # requisite options
        spawner.option("--parent-front", Global.front.uri)
        spawner.option("--my-ip-address", Global.my_ip_address)
        spawner.option("--presence-port", Global.presence_port.to_s)

        # optionals
        spawner.option("--debug") if Pione.debug_mode?
        spawner.option("--show-communication") if Global.show_communication
        spawner.option("--show-presence-notifier") if Global.show_presence_notifier

        spawner.spawn
      end

      #
      # option
      #

      define_info do
        set_name "pione-tuple-space-receiver"
        set_tail {|cmd|
          front = Global.front.uri
          parent_front = cmd.option[:parent_front].uri
          "{Front: %s, ParentFront: %s}" % [front, parent_front]
        }
        set_banner(Util::Indentation.cut(<<-TXT))
          Run tuple space receiver process for receiving tuple space presence
          notifier. This command is launched by other processes like pione-broker
          normally, but you can force to start by calling with --no-parent option.
        TXT
      end

      define_option do
        use :debug
        use :color
        use :my_ip_address
        use :parent_front
        use :show_communication
        use :show_presence_notifier

        define(:presence_port) do |item|
          item.long = "--presence-port=PORT"
          item.desc = "set presence port number"
          item.action = lambda do |option, port|
            Global.presence_port = port.to_i
          end
        end
      end

      attr_reader :tuple_space_receiver

      def create_front
        Front::TupleSpaceReceiverFront.new(self)
      end

      prepare do
        # add child process to the parent
        option[:parent_front].add_child(Process.pid, Global.front.uri)

        # create a tuple space receiver agent
        @tuple_space_receiver = Agent::TupleSpaceReceiver.new(option[:parent_front].broker)

        # set my uri to parent front as its provider
        option[:parent_front].set_tuple_space_receiver(Global.front.uri)
      end

      start do
        # start provider activity and wait it to be terminated
        @tuple_space_receiver.start
        @tuple_space_receiver.wait_until_terminated(nil)
      end

      terminate do
        Global.monitor.synchronize do
          @tuple_space_receiver.terminate
        end
      end
    end
  end
end
