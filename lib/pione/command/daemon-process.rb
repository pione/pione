module Pione
  module Command
    class DaemonProcess < FrontOwner
      define_option("--daemon", "enable daemon mode") do
        @daemon = true
      end

      def initialize
        super
        @daemon = false
      end

      def prepare
        super
        Process.daemon(true, true) if @daemon
      end
    end
  end
end
