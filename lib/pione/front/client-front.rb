module Pione
  module Front
    # ClientFront is a front interface for +pione-client+ command.
    class ClientFront < BasicFront
      # Create a new front.
      def initialize
        super(Global.client_front_port_range)
      end

      def set_tuple_space(tuple_space)
        @tuple_space = tuple_space
      end

      # Get client's tuple space. +tuple_space_id+ is ignored.
      def get_tuple_space(tuple_space_id)
        @tuple_space
      end
    end
  end
end
