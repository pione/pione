module Pione
  module Command
    class PioneStandAlone < BasicCommand
      include ProcessClient

      def initialize
        super
      end

      def run
        # front
        front = Pione::Front::StandAloneFront.new

        #
        # start rule handling
        #
        while true do
          if handler = @doc.root_rule(@params).make_handler(@tuple_space_server)
            handler.handle
          else
            user_message "no inputs"
          end

          break unless @stream
          sleep 5
          user_message "check new inputs"
        end

        front.terminate
      end
    end
  end
end
