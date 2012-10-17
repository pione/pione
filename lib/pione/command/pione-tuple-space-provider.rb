module Pione
  module Command
    class PioneTupleSpaceProvider < BasicCommand
      def run
        # create a front server
        Pione::Front::TupleSpaceProviderFront.new(
          @druby_port,
          @presence_port
        ).start
      end

      define_option("--druby-port port", "druby port number for front server") do |port|
        @druby_port = port.to_i
      end

      define_option("--presence-port port", "presence port number") do |port|
        @presence_port = port.to_i
      end
    end
  end
end
