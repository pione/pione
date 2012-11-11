module Pione
  module Command
    class FrontOwnerCommand < BasicCommand
      # Runs the command.
      def run
        parse_options
        validate_options
        setup_front
        prepare
        $PROGRAM_NAME = program_name
        start
      end

      # Setups font server.
      # @return [void]
      def setup_front
        Global.front = create_front
      end

      # Creates a front server. This method should be overridden in subclasses.
      # @return [BasicFront]
      #   front server
      def create_front
        raise NotImplementedError
      end

      def terminate
        super
        DRb.stop_service
      end
    end
  end
end
