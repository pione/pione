module Pione
  module Agent
    # TaskWorker is an agent to process tasks
    class TaskWorker < TupleSpaceClient
      set_agent_type :task_worker, self

      #
      # instance methods
      #

      attr_reader :tuple_space
      attr_reader :execution_thread
      attr_accessor :once # the agent will be killed at task completion if true

      def initialize(tuple_space, features, env=nil)
        super(tuple_space)
        @tuple_space = tuple_space
        @features = features
        @env = env || get_environment
      end

      #
      # activity definitions
      #

      define_transition :take_task
      define_transition :init_task
      define_transition :execute_task
      define_transition :finalize_task
      define_transition :connection_error

      chain :init => :take_task
      chain :take_task => :init_task
      chain :init_task => :execute_task
      chain :execute_task => :finalize_task
      chain :finalize_task => lambda {|agent, result| agent.once ? :terminate : :take_task}
      chain :connection_error => :terminate

      define_exception_handler Restart => :take_task
      define_exception_handler DRb::DRbConnError => :connection_error

      #
      # transitions
      #

      # Take a task and turn it to foreground.
      def transit_to_take_task
        return take(TupleSpace::TaskTuple.new(features: @features))
      end

      # Initialize the task.
      def transit_to_init_task(task)
        # make flag tuples
        working = TupleSpace::WorkingTuple.new(task.domain_id, task.digest)
        foreground = TupleSpace::ForegroundTuple.new(task.domain_id, task.digest)

        if read!(working)
          # the task is working already, so we will dicard the task
          raise Restart.new
        else
          # turn foreground flag on
          write(working)
          write(foreground)
          # go next transition
          return task
        end
      rescue Rinda::RedundantTupleError
        raise Restart.new
      end

      # Execute the task.
      def transit_to_execute_task(task)
        # setup rule engine
        engine = make_engine(task)

        # start the engine
        @execution_thread = Thread.new do
          begin
            engine.handle
          rescue RuleEngine::ActionError => e
            write(TupleSpace::CommandTuple.new("terminate", [System::Status.error(e)]))
            terminate
          end
        end

        # spawn child task worker if flow
        if engine.rule_definition.rule_type == "flow"
          spawn_child_task_worker(task)
        end

        # wait until the engine ends
        @execution_thread.join

        # go next transition
        return task
      end

      # Finalize the task. This method will turn working flag off and background.
      def transit_to_finalize_task(task)
        take!(TupleSpace::WorkingTuple.new(task.domain_id, task.digest))
        take!(TupleSpace::ForegroundTuple.new(task.domain_id, task.digest))
      end

      # Report the connection error.
      def transit_to_connection_error(e)
        Log::SystemLog.warn("task worker agent was disconnected from tuple space unexpectedly, goes to termination.")
      end

      #
      # helper methods
      #

      # Get a environment object from tuple space.
      def get_environment
        if env = read!(TupleSpace::EnvTuple.new)
          env.obj
        else
          raise TupleSpaceError.new("\"env\" tuple not found.")
        end
      end

      # Make an engine from the task.
      def make_engine(task)
        RuleEngine.make(
          @tuple_space,
          @env,
          task.package_id,
          task.rule_name,
          task.inputs,
          task.param_set,
          task.domain_id,
          task.caller_id
        )
      end

      # Spawn child task worker. This method repeats to create a child agent
      # while rule execution thread is alive.
      def spawn_child_task_worker(task)
        child_agent = nil
        foreground = TupleSpace::ForegroundTuple.new(task.domain_id, task.digest)

        # child worker loop
        while @execution_thread.alive? do
          if @execution_thread.status == "sleep"
            if child_agent.nil? or child_agent.terminated?
              # when there isn't active child agent
              child_agent = self.class.new(tuple_space_server, @features, @env)
              child_agent.once = true

              # make log record
              record = Log::CreateChildTaskWorkerProcessRecord.new.tap do |x|
                x.parent = uuid
                x.child = child_agent.uuid
              end

              # spawn child agent with logging
              with_process_log(record) do
                # turn background
                take!(foreground)
                # start child agent
                child_agent.start
              end

              # wait until the child agent completes the task
              child_agent.wait_until_terminated(nil)
            end
          else
            sleep 0.1 # FIXME : rewrite this sleep by more sophisticated way
          end
        end

        # turn foreground
        write(foreground) unless read!(foreground)
      end
    end
  end
end
