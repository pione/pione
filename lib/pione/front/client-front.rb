module Pione
  module Front
    # ClientFront is a front interface for +pione-client+ command.
    class ClientFront < BasicFront
      # Create a new front.
      def initialize(cmd)
        super(cmd, Global.client_front_port_range)
        @lock = Mutex.new
      end

      def set_tuple_space(tuple_space)
        @tuple_space = tuple_space
      end

      # Get client's tuple space. +tuple_space_id+ is ignored.
      def get_tuple_space(tuple_space_id)
        @tuple_space
      end

      def notice_tuple_space_broker(tuple_space_broker_front_uri)
        if @cmd.model[:thread] && @cmd.model[:thread].stop?
          @lock.synchronize do
            if @cmd.model[:thread] && @cmd.model[:thread].stop?
              begin
                @cmd.model[:tuple_space_broker_front_uri] = tuple_space_broker_front_uri
                front = DRb::DRbObject.new_with_uri(tuple_space_broker_front_uri)
                tuple_space_provider_front_uri = front.create()
                tuple_space_provider = DRb::DRbObject.new_with_uri(tuple_space_provider_front_uri)
                @cmd.model[:tuple_space] = tuple_space_provider.tuple_space
              rescue Exception => e
                @cmd.model[:thread] = nil
                @cmd.model[:tuple_space] = nil
                Log::Debug.system("Bad tuple space broker found.", e)
                return false
              end

              @cmd.model[:thread].run
              @cmd.model[:thread] = nil
              return true
            end
          end
        else
          return false
        end
      end
    end
  end
end
