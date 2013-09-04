module Pione
  module Front
    # ClientFront is a front class for +pione-client+ command.
    class ClientFront < BasicFront
      include TupleSpaceProviderOwner

      forward :@command, :tuple_space
      forward :@command, :name

      # Create a new front.
      def initialize(command)
        super(command, Global.client_front_port_range)
      end

      # Get client's tuple space. +tuple_space_id+ is ignored.
      def get_tuple_space(tuple_space_id)
        @command.tuple_space
      end
    end
  end
end
