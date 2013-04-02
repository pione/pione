module Pione
  module Command
    # PioneBroker is a command for starting a PIONE broker agent. Brokers
    # provides task processing ability to the system.
    class PioneBroker < DaemonProcess
      define_info do
        set_name "pione-broker"
        set_tail {|cmd| "{TaskWorker: %s}" % cmd.option[:task_worker]}
        set_banner "Run broker agent to launch task workers."
      end

      define_option do
        use Option::TupleSpaceReceiverOption
        use Option::TaskWorkerOwnerOption

        validate do |data|
          unless data[:task_worker] > 0
            abort("error: no task worker resources")
          end
        end
      end

      attr_reader :broker

      def create_front
        Front::BrokerFront.new(self)
      end

      prepare do
        @broker = Pione::Agent[:broker].new(
          option[:features],
          task_worker_resource: option[:task_worker]
        )
        @tuple_space_receiver = Pione::TupleSpaceReceiver.instance
      end

      start do
        # start broker agent
        @broker.start

        # start tuple space receiver with the broker agent
        @tuple_space_receiver.register(@broker)

        # wait
        begin
          DRb.thread.join
        rescue DRb::ReplyReaderThreadError
          retry
        end
      end

      terminate do
        @broker.terminate
      end
    end
  end
end
