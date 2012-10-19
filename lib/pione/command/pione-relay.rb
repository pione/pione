module Pione
  module Command
    class PioneTupleSpaceGateway < BasicCommand
      def run
        Front::TupleSpaceGatewayFront.start
      end
    end
  end
end
