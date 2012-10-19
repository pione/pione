module Pione
  module Command
    # This is a class for +pione-task-worker+ command. +pione-task-worker+
    # starts a task worker agent with tuple space server.
    class PioneTaskWorker < BasicCommand
      define_option('--caller-front uri') do |uri|
        @caller_front = DRbObject.new_with_uri(uri)
      end

      define_option('--connection-id id') do |id|
        @connection_id = id
      end

      def create_front
        Pione::Front::TaskWorkerFront.new(@caller_front, @connection_id)
      end

      def validate_options
        # check requisite options
        abort("error: no caller front address") if @caller_front.nil?
        abort("error: no connection id") if @connection_id.nil?

        # get the caller front server
        begin
          @caller_front.uuid
        rescue => e
          abort("pione-task-worker cannot get the caller front server: %s" % e)
        end
      end

      def run
        # start task worker activity
        @agent.start

        # wait...
        begin
          @agent.running_thread.join
          # terminate
          terminate
        rescue DRb::DRbConnError
          # do nothing
        end
      end
    end
  end
end
