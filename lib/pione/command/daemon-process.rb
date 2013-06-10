module Pione
  module Command
    # DaemonProcess is a class for commands that enable to daemonize.
    class DaemonProcess < FrontOwnerCommand
      prepare(:post) do
        Process.daemon(true, true) if option[:daemon]
      end
    end
  end
end
