module Pione
  module Command
    class PioneTupleSpaceReceiver < ChildProcess
      set_program_name("pione-tuple-space-receiver") do
        parent_front = @no_parent_mode ? "nil" : @parent_front.uri
        "<front=%s, parent=%s>" % [Global.front.uri, parent_front]
      end

      set_program_message <<TXT
Runs tuple space receiver process for receiving tuple space presence
notifier. This command is launched by other processes like pione-broker
normally, but you can force to start by calling with --no-parent option.
TXT

      use_option_module CommandOption::TupleSpaceReceiverOption

      attr_reader :tuple_space_receiver

      def create_front
        Front::TupleSpaceReceiverFront.new(self)
      end

      def prepare
        super
        @tuple_space_receiver = TupleSpaceReceiver.new
      end

      def start
        super

        # start provider activity
        @tuple_space_receiver.start

        # set my uri to parent front as its provider
        unless @no_parent_mode
          @parent_front.set_tuple_space_receiver(Global.front.uri)
        end

        # wait
        DRb.thread.join
      rescue DRb::ReplyReaderThreadError => e
        # ignore reply reader error
      end

      def terminate
        puts "terminate %s" % program_name
        begin
          @tuple_space_receiver.terminate
        rescue DRb::DRbConnError
        end
        super
      end
    end
  end
end
