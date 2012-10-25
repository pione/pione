module Pione
  module Command
    # PioneTupleSpaceProvider is for +pione-tuple-space-provider+ command.
    class PioneTupleSpaceProvider < ChildProcess
      set_program_name("pione-tuple-space-provider") do
        "--presence-port %s --caller-front %s" % [@presence_port, @caller_front.uri]
      end

      define_option("--presence-port port", "presence port number") do |port|
        @presence_port = port.to_i
      end

      define_option("--relay uri", "relay server uri") do |uri|
        @relay = uri
      end

      attr_reader :tuple_space_provider

      def initialize
        @presence_port = nil
        @caller_front = nil
        @relay = nil
      end

      def validate_options
        super
        abort("error: no presence port") unless @presence_port
      end

      def create_front
        Pione::Front::TupleSpaceProviderFront.new(self, nil)
      end

      def prepare
        super
        @tuple_space_provider = TupleSpaceProvider.new(@presence_port)
      end

      def start
        super
        # start provider activity
        @tuple_space_provider.start
        # set my uri to caller front as its provider
        @caller_front.set_tuple_space_provider(Global.front.uri)
        DRb.thread.join
      end

      def terminate
        @tuple_space_provider.terminate
        super
      end
    end
  end
end
