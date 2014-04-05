module Pione
  module Command
    # Spawner is a utility class for calling pione commands as different
    # process. We assume both caller and callee commands have front server.
    class Spawner
      attr_reader :pid         # PID of spawned child process
      attr_reader :child_front # front URI of spawned child process
      attr_reader :thread      # watch thread for spawned child process

      def initialize(model, name)
        @model = model # caller's model
        @name = name   # callee command name
        @argv = []     # callee command arguments
      end

      # Spawn the command process.
      def spawn
        Log::Debug.system('process "%{name}" is spawned with arguments %{argv}' % {name: @name, argv: @argv})

        # create a new process and watch it
        @pid = Process.spawn(@name, *@argv)

        # keep to watch child process
        @thread = Process.detach(@pid)

        # find child front while child process is alive
        Timeout.timeout(10) do
          while @thread and @thread.alive? do
            # find front and save its uri and pid
            if child_front = find_child_front(@pid)
              @child_front = child_front

              return self
            else
              sleep 0.1
            end
          end

          # when process is dead, raise an error
          raise SpawnError.new(@model[:scenario_name], @name, @argv, "child process is dead")
        end
      rescue Timeout::Error
        raise SpawnError.new(@model[:scenario_name], @name, @argv, "timed out")
      rescue Object => e
        if e.kind_of?(SpawnError)
          raise
        else
          raise SpawnError.new(@model[:scenario_name], @name, @argv, e.message)
        end
      end

      # Append arguments to the command.
      def option(*argv)
        @argv += argv.map {|val| val.to_s}
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
        if child_front_uri = @model[:front].child_front_uri(pid)
          return DRbObject.new_with_uri(child_front_uri.to_s).tap do |front|
            timeout(1) {front.ping} # test connection
          end
        end
      rescue Timeout::Error
        return nil
      end
    end
  end
end
