module Pione
  module Front
    # ClientFront is a front class for +pione-client+ command.
    class ClientFront < BasicFront
      extend Forwardable
      include TaskWorkerOwner

      def_delegator :@command, :tuple_space_server

      # Create a new front.
      def initialize(command)
        super(command, nil)
        initialize_task_worker_owner
      end

      # Returns client's tuple space server for task workers.
      # @param [String] connection_id
      #   connection id of task worker
      # @return [TupleSpaceServer]
      #   tuple space server
      def get_tuple_space_server(connection_id)
        tuple_space_server
      end

      # Sets the uri as tuple space provider.
      def set_tuple_space_provider(uri)
        Pione.set_tuple_space_provider_uri(uri)
      end
    end
  end
end
