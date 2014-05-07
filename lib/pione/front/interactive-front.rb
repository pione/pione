module Pione
  module Front
    # InteractiveFront is a front interface for +pione-interactive+ command.
    class InteractiveFront < BasicFront
      def initialize(cmd)
        super(cmd, Global.interactive_front_port_range)
      end

      # Read data string from the path. This path should be relative from public
      # directory of pione-interactive.
      #
      # @param [String] path
      #   relative path from public directory
      def file(path)
        (@cmd.model[:public] + path).read
      end
    end
  end
end
