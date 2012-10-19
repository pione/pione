module Pione
  module Command
    # PioneTupleSpaceProvider is for +pione-tuple-space-provider+ command.
    class PioneTupleSpaceProvider < BasicCommand
      define_option("--druby-port port", "druby port number for front server") do |port|
        @druby_port = port.to_i
      end

      define_option("--presence-port port", "presence port number") do |port|
        @presence_port = port.to_i
      end

      define_option("--caller-front uri", "caller's front uri") do |uri|
        @caller_front = DRbObject.new_with_uri(uri)
      end

      attr_reader :tuple_space_provider

      def initialize
        @tuple_space_provider = TupleSpaceProvider.new(@presence_port)
      end

      def create_front
        Pione::Front::TupleSpaceProviderFront.new(self)
      end

      def run
        # start provider activity
        @tuple_space_provider.start
        # set my uri to caller front as its provider
        @caller_front.set_tuple_space_provider(Pione.front.uri)
        DRb.thread.join
      end

      def terminate
        @tuple_space_provider.terminate
        super
      end
    end
  end
end
