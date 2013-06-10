module Pione
  module Command
    # FrontOwnerCommand is a parent of classes that own front server.
    class FrontOwnerCommand < BasicCommand
      prepare do
        Global.front = create_front
      end

      # Create a front server. This method should be overridden in subclasses.
      #
      # @return [BasicFront]
      #   front server
      def create_front
        raise NotImplementedError
      end

      terminate do
        Global.monitor.synchronize do
          # stop DRb service
          # DRb.stop_service
        end
      end
    end
  end
end
