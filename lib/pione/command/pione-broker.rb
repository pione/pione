module Pione
  module Command
    class PioneBroker < DaemonProcess
      set_program_name "pione-broker" do
        "--task-worker %s" % @resource
      end

      define_option(
        '-r n',
        '--worker-resource n',
        'task worker resource size'
      ) do |n|
        @resource = n.to_i
      end

      attr_reader :broker

      def initialize
        @resource = [Util.core_number - 1, 1].max
      end

      def create_front
        Front::BrokerFront.new(self)
      end

      def validate_options
        unless @resource > 0
          abort("error: no task worker resources")
        end
      end

      def prepare
        super
        @broker = Pione::Agent[:broker].new(task_worker_resource: @resource)
        @tuple_space_receiver = Pione::TupleSpaceReceiver.instance
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
