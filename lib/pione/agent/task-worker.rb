module Pione
  module Agent
    # TaskWorker is an agent to process tasks
    class TaskWorker < TupleSpaceClient
      set_agent_type :task_worker, self

      #
      # activity definitions
      #

      define_transition :take_task
      define_transition :init_task
      define_transition :execute_task
      define_transition :finalize_task

      chain :init => :take_task
      chain :take_task => :init_task
      chain :init_task => :execute_task
      chain :execute_task => :finalize_task
      chain :finalize_task => lambda {|agent, result| agent.once ? :terminate : :take_task}

      define_exception_handler Restart => :take_task

      #
      # instance methods
      #

      attr_reader :execution_thread
      attr_accessor :once # the agent will be killed at task completion if true

      def initialize(space, features, env=nil)
        super(space)
        @space = space
        @env = env || get_environment
        @features = features
      end

      #
      # actions
      #

      # Take a task and turn it to foreground.
      def transit_to_take_task
        return take(Tuple[:task].new(features: @features))
      rescue DRb::DRbConnError, DRb::ReplyReaderThreadError => e
        # FIXME : kind of this errors are happened in any situations, so we need
        #         to handle it by more general way.

        # tuple space may be closed
        ErrorReport.warn("Disconnected in task wainting of task worker agent.", self, e, __FILE__, __LINE__)
        terminate
      end

      # Initialize the task.
      def transit_to_init_task(task)
        # make flag tuples
        working = Tuple[:working].new(task.domain_id, task.digest)
        foreground = Tuple[:foreground].new(task.domain_id, task.digest)

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
        @execution_thread = Thread.new {engine.handle}

        # spawn child task worker if flow
        if engine.rule_definition.rule_type == :flow
          spawn_child_task_worker(task)
        end

        # wait until the engine ends
        @execution_thread.join

        # go next transition
        return task
      end

      # Finalize the task. This method will turn working flag off and background.
      def transit_to_finalize_task(task)
        take!(Tuple[:working].new(task.domain_id, task.digest))
        take!(Tuple[:foreground].new(task.domain_id, task.digest))
      end

      #
      # helper methods
      #

      # Get a environment object from tuple space.
      def get_environment
        if env = read!(Tuple[:env].new)
          env.obj
        else
          raise TupleSpaceError.new("\"env\" tuple not found.")
        end
      end

      # Make an engine from the task.
      def make_engine(task)
        RuleEngine.make(
          @space,
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
        foreground = Tuple[:foreground].new(task.domain, task.digest)

        # child worker loop
        while @execution_thread.alive? do
          if @execution_thread.status == "sleep"
            if child_agent.nil? or not(child_agent.terminated?)
              # when there isn't active child agent
              child_agent = self.class.new(tuple_space_server, @env, @features)
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
