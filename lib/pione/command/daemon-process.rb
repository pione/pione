module Pione
  module Command
    class DaemonProcess < FrontOwnerCommand
      use_option_module CommandOption::DaemonOption

      def initialize
        super
        @daemon = false
      end

      def prepare
        super
        puts Global.front.uri
        Process.daemon(true, true) if @daemon
      end
    end
  end
end
