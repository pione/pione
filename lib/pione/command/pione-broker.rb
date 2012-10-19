module Pione
  module Command
    class PioneBroker < BasicCommand
      def self.default_task_worker_size
        [Pione.get_core_number - 1, 1].max
      end

      define_option(
        '-r n',
        '--worker-resource=n',
        'task worker resource size(default %s)' % default_task_worker_size
      ) do |n|
        @resource = n.to_i
        unless @resource > 0
          abort "invalid resource size: %s" % option.resource
        end
      end

      def initialize
        @resource = self.class.default_task_worker_size
      end

      def create_front
        Pione::Front::BrokerFront.new(@resource)
      end

      def validate_options
        unless @resource > 0
          abort("error: no task worker resources")
        end
      end
    end
  end
end
