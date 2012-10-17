module Pione
  module Command
    class PioneTupleSpaceReceiver < BasicCommand
      def run
        Front::TupleSpaceReceiverFront.start
      end

      define_option('--druby-port port', 'druby port number') do |num|
        @druby_port = num
      end
    end
  end
end
