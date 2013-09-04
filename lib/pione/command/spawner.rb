module Pione
  module Command
    class Spawner
      def initialize(command_name)
        @command_name = command_name
        @cmd = [command_name]
      end

      # Spawn the command.
      def spawn
        # create provider process
        pid = Process.spawn(*@cmd)
        thread = Process.detach(pid)

        # find child front while child process is alive
        timeout(5) do
          while thread and thread.alive?
            if child_front = find_child_front(pid)
              return child_front
            else
              sleep 0.1
            end
          end
        end

        # failed to run the command
        raise SpawnError.new("We failed to run %s command." % @command_name)
      rescue Timeout::Error
        raise SpawnError.new("We try to run command %s, but it timeouted. (5 sec)" % @command_name)
      end

      # Add the command option.
      def option(*args)
        @cmd += args
      end

      private

      # Find child front. Spawned child process sets URI of the front to my
      # front, so we get it.
      def find_child_front(pid)
        if child_front_uri = Global.front.child[pid]
          child_front = DRbObject.new_with_uri(child_front_uri)
          child_front.uuid # try connection
          return child_front
        end
      rescue
        # do nothing
      end
    end
  end
end
