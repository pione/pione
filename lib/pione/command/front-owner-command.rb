module Pione
  module Command
    # FrontOwnerCommand is a parent of classes that own front server.
    class FrontOwnerCommand < BasicCommand
      define_option do
        option("--my-ip-address=ADDRESS", "set my IP address") do |data, address|
          Global.my_ip_address = address
        end
      end

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
