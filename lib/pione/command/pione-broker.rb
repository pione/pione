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
        use :color
        use :daemon
        use :debug
        use :features
        use :my_ip_address
        use :show_communication
        use :task_worker

        validate do |option|
          unless option[:task_worker] > 0
            abort("error: no task worker resources")
          end
        end
      end

      attr_reader :broker

      def create_front
        Front::BrokerFront.new(self)
      end

      prepare do
        @broker = Agent::Broker.new(option[:features], task_worker_resource: option[:task_worker])
        @tuple_space_receiver = PioneTupleSpaceReceiver.spawn
      end

      start do
        # start broker agent and wait it will be terminated
        @broker.start
        puts "*** start pione-broker ***"
        @broker.wait_until_terminated(nil)
      end

      terminate do
        @broker.terminate unless @broker.terminated?
        puts "*** end pione-broker ***"
      end
    end
  end
end
