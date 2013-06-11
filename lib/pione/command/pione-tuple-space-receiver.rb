module Pione
  module Command
    # PioneTupleSpaceReceiver is a command that launchs tuple space receiver
    # agent.
    class PioneTupleSpaceReceiver < ChildProcess
      define_info do
        set_name "pione-tuple-space-receiver"
        set_tail {|cmd|
          front = Global.front.uri
          parent_front = cmd.option[:no_parent_mode] ? "nil" : cmd.option[:parent_front].uri
          "{Front: %s, ParentFront: %s}" % [front, parent_front]
        }
        set_banner <<TXT
Run tuple space receiver process for receiving tuple space presence
notifier. This command is launched by other processes like pione-broker
normally, but you can force to start by calling with --no-parent option.
TXT
      end

      define_option do
        use :debug
        use :color
        use :my_ip_address
        use :no_parent
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
        @tuple_space_receiver = TupleSpaceReceiver.new
      end

      start do
        begin
          # start provider activity
          @tuple_space_receiver.start

          # set my uri to parent front as its provider
          unless option[:no_parent_mode]
            option[:parent_front].set_tuple_space_receiver(Global.front.uri)
          end

          # wait
          DRb.thread.join
        rescue DRb::ReplyReaderThreadError => e
          # ignore reply reader error
        end
      end

      terminate do
        Global.monitor.synchronize do
          @tuple_space_receiver.terminate
        end
      end
    end
  end
end
