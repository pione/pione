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

        # fail to spawn if the monitor thread is nil
        unless @thread
          return self
        end

        # find child front while child process is alive
        Timeout.timeout(10) do
          while @thread.alive? do
            # find front and save its uri and pid
            if child_front = find_child_front(@pid)
              @child_front = child_front

              return self
            else
              sleep 0.1
            end
          end

          # error if the process has failed
          unless not(@thread.alive?) and @thread.value.success?
            raise SpawnError.child_process_is_dead(@model[:scenario_name], @name, @argv)
          end

          return self
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

      # Add arguments as command arguments.
      def option(*argv)
        @argv += argv.map {|val| val.to_s}
      end

      # Add arguments if the condition is true.
      def option_if(cond, *args)
        if cond
          option(*args)
        end
      end

      # Add the option name and the value as command arguments. If the value
      # doesn't exist in the table or the value is `nil`, no options are
      # added. This is useful for the case a caller's command option passes
      # callee's.
      #
      # @param [Hash] table
      #   value table
      # @param [Symbol] key
      #   key of the value table
      # @param [String] option_name
      #   option name
      # @return [void]
      def option_from(table, key, option_name, converter=nil)
        if table[key]
          val = table[key]
          val = converter.call(val) if converter
          option(option_name, val)
        end
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
