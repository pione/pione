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

        # register PID to front server for termination
        Global.front.child[pid] = nil if Global.front

        # keep to watch child process
        thread = Process.detach(pid)

        begin
          # find child front while child process is alive
          retriable :on => [SpawnerRetry, Timeout::Error], :tries => 30, :interval => 0.1 do
            # when process is dead, raise an error
            if thread.nil? or not(thread.alive?)
              raise SpawnError.new("%s failed to spawn %s." % [Global.command.command_name, @name])
            end

            # find front and save its uri and pid
            @child_front = find_child_front(pid) || (raise SpawnerRetry)
            @pid = pid
            @thread = thread

            return self
          end
        rescue Exception => e
          raise SpawnError.new("%s failed to spawn %s: %s" % [Global.command.command_name, @name, e.message])
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
        if child_front_uri = Global.front.child[pid]
          return DRbObject.new_with_uri(child_front_uri).tap do |front|
            timeout(1) {front.ping} # test connection
          end
        end
      end
    end
  end
end
