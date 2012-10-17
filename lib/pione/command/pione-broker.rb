module Pione
  module Command
    class PioneBroker < BasicCommand
      def self.default_task_worker_size
        Pione.get_core_number - 1
      end

      def initialize
        @resource = self.class.default_task_worker_size
      end

      def run
        Pione::Front::BrokerFront.new(@resource).start
      end

      msg = 'task worker resource size(default %s)' % default_task_worker_size
      define_option('-r n', '--worker-resource=n', msg) do |n|
        @resource = n.to_i
        unless @resource > 0
          puts "invalid resource size: %s" % option.resource
          exit
        end
      end
    end
  end
end
