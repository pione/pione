module Pione
  module Command
    class PioneTaskWorker < BasicCommand
      def run
        validate_options
        Pione::Front::TaskWorkerFront.new(@caller_front, @connection_id).start
      end

      define_option('--caller-front uri') do |uri|
        @caller_front = DRbObject.new_with_uri(uri)
      end

      define_option('--connection-id id') do |id|
        @connection_id = id
      end

      def validate_options
        # get the caller front server
        begin
          @caller_front.uuid
        rescue => e
          abort("pione-task-worker cannot get the caller front server: %s" % e)
        end

        # check connection_id
        unless @connection_id
          abort("invalid connection id: %s" % @connection_id)
        end
      end
    end
  end
end
