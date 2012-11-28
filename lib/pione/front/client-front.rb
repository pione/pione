module Pione
  module Front
    # ClientFront is a front class for +pione-client+ command.
    class ClientFront < BasicFront
      extend Forwardable
      include TaskWorkerOwner
      include TupleSpaceProviderOwner

      def_delegator :@command, :tuple_space_server
      def_delegator :@command, :name

      # Create a new front.
      def initialize(command)
        super(command, Global.client_front_port_range)
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
    end
  end
end
