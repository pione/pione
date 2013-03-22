module Pione
  module Command
    class FrontOwnerCommand < BasicCommand
      define_option("--my-ip-address=ADDRESS", "set my IP address") do |address|
        Global.my_ip_address = address
      end

      # Runs the command.
      #
      # @return [void]
      def run
        parse_options
        validate_options
        setup_front
        prepare
        setup_program_name
        start
      end

      # Setup font server.
      #
      # @return [void]
      def setup_front
        Global.front = create_front
      end

      # Create a front server. This method should be overridden in subclasses.
      #
      # @return [BasicFront]
      #   front server
      def create_front
        raise NotImplementedError
      end

      # Terminate PIONE front. Stop DRb service.
      #
      # @return [void]
      def terminate
        Global.monitor.synchronize do
          # stop DRb service
          DRb.stop_service
          # go to other termination processes
          super
        end
      end
    end
  end
end
