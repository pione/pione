module Pione
  module Command
    # Spawner is a utility class for calling pione commands as different
    # process. We assume both caller and callee commands have front server.
    class Spawner
      attr_reader :pid         # PID of spawned child process
      attr_reader :child_front # front URI of spawned child process
      attr_reader :thread      # watch thread for spawned child process

      def initialize(name)
        @name = name # callee command name
        @args = []   # callee command arguments
      end

      # Spawn the command process.
      def spawn
        Log::Debug.system("process \"%s\" is spawned with arguments %s" % [@name, @args])

        # create a new process and watch it
        pid = Process.spawn(@name, *@args)

        # keep to watch child process
        thread = Process.detach(pid)

        # find child front while child process is alive
        Timeout.timeout(10) do
          while thread and thread.alive? do
            # find front and save its uri and pid
            if child_front = find_child_front(pid)
              @child_front = child_front
              @pid = pid
              @thread = thread

              return self
            else
              sleep 0.2 and next
            end
          end

          # when process is dead, raise an error
          raise SpawnError.new("%s failed to spawn %s %s." % [Global.command.command_name, @name, @args])
        end
      rescue Timeout::Error
        raise SpawnError.new("%s tried to spawn %s %s, but timeouted." % [Global.command.command_name, @name, @args])
      rescue Object => e
        if e.kind_of?(SpawnError)
          raise
        else
          raise SpawnError.new("%s failed to spawn %s %s: %s" % [Global.command.command_name, @name, @args, e.message])
        end
      end

      # Append arguments to the command.
      def option(*args)
        @args += args
      end

      # Register the block that is executed when the spawned process is terminated.
      def when_terminated(&b)
        Thread.new do
          @thread.join
          b.call
        end
      end

      private

      # Find child front by PID. Spawned child process sets the front server's
      # URI to children table of my front, so we get it from my front and create
      # the reference.
      def find_child_front(pid)
        if child_front_uri = Global.front.child_front_uri(pid)
          return DRbObject.new_with_uri(child_front_uri).tap do |front|
            timeout(1) {front.ping} # test connection
          end
        end
      rescue Timeout::Error
        return nil
      end
    end
  end
end
