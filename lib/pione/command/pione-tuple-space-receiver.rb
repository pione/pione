module Pione
  module Command
    class PioneTupleSpaceReceiver < ChildProcess
      set_program_name("pione-tuple-space-receiver") do
        "--presence-port %s --caller-front %s" % [@presence_port, @caller_front.uri]
      end

      define_option("--presence-port port", "presence port number") do |port|
        @presence_port = port.to_i
      end

      attr_reader :tuple_space_receiver

      def create_front
        Front::TupleSpaceReceiverFront.new(self, nil)
      end

      def prepare
        super
        @tuple_space_receiver = TupleSpaceReceiver.new(@presence_port)
      end

      def start
        super

        # start provider activity
        @tuple_space_receiver.start
        # set my uri to caller front as its provider
        @caller_front.set_tuple_space_receiver(Global.front.uri)
        DRb.thread.join
      end

      def terminate
        @tuple_space_receiver.terminate
        super
      end
    end
  end
end
