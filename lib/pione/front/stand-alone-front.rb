module Pione
  module Front
    # StandAloneFront is a front class for pione-stand-alone command.
    class StandAloneFront < BasicFront
      include TaskWorkerOwner

      attr_accessor :tuple_space_server

      def initialize
        super()
        initialize_task_worker_owner
      end

      def get_tuple_space_server(connection_id)
        @tuple_space_server
      end
    end
  end
end
