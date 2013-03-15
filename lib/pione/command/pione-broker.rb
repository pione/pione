module Pione
  module Command
    class PioneBroker < DaemonProcess
      set_program_name "pione-broker" do
        "--task-worker %s" % @task_worker
      end

      set_program_message <<TXT
Runs the broker to launch task workers.
TXT

      use_option_module CommandOption::TupleSpaceReceiverOption
      use_option_module CommandOption::TaskWorkerOwnerOption

      attr_reader :broker

      def initialize
        @task_worker = [Util.core_number - 1, 1].max
        @features = nil
      end

      def create_front
        Front::BrokerFront.new(self)
      end

      def validate_options
        unless @task_worker > 0
          abort("error: no task worker resources")
        end
      end

      def prepare
        super
        @broker = Pione::Agent[:broker].new(@features, task_worker_resource: @task_worker)
        @tuple_space_receiver = Pione::TupleSpaceReceiver.instance
      end

      def start
        # start broker
        @broker.start

        # start tuple space receiver
        @tuple_space_receiver.register(@broker)

        # wait
        begin
          DRb.thread.join
        rescue DRb::ReplyReaderThreadError
          retry
        end
      end
    end
  end
end
