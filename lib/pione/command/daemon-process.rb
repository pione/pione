module Pione
  module Command
    # DaemonProcess is a class for commands that enable to daemonize.
    class DaemonProcess < FrontOwnerCommand
      define_option do
        default :daemon, false

        # --daemon
        option("--daemon", "turn on daemon mode") do |data|
          data[:daemon] = true
        end
      end

      prepare(:post) do
        Process.daemon(true, true) if option[:daemon]
      end
    end
  end
end
