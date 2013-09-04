module Pione
  module Command
    # FrontOwnerCommand is a parent of classes that own front server.
    class FrontOwnerCommand < BasicCommand
      prepare do
        Global.front = create_front
      end

      # Create a front server. This method should be overridden in subclasses.
      def create_front
        raise NotImplementedError
      end

      prepare(:post) do
        if option[:parent_front]
          ParentFrontWatchDog.start
        end
      end
    end

    class ParentFrontWatchDog
      def self.start
        watchdog = new
        Thread.new do
          while true
            watchdog.watch
            sleep 3
          end
        end
      end

      def initialize(command)
        @command = command
      end

      def watch
        # PPID 1 means the parent process is dead
        execute if Process.ppid == 1
        # disconnected
        Util.if_error{command.option[:parent_front].uuid}.call{execute}
      end

      def execute
        @command.terminate
      end
    end
  end
end
