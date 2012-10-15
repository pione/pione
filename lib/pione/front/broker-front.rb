module Pione
  module Front
    class BrokerFront < BaseFront
      include TaskWorkerOwner

      def initialize(resource)
        @broker = Pione::Agent[:broker].new(task_worker_resource: resource)
        @tuple_space_receiver = Pione::TupleSpaceReceiver.instance
        initialize_task_worker_owner
      end

      def get_tuple_space_server(connection_id)
        @broker.get_tuple_space_server(connection_id)
      end

      def add_task_worker(task_worker)
        @broker.add_task_worker(task_worker)
      end

      def start
        # start broker
        @broker.start

        # start tuple space receiver
        @tuple_space_receiver.register(@broker)

        # wait
        DRb.thread.join
      end
    end
  end
end
