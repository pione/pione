module Pione
  module Agent
    # TaskWorker is an agent to process tasks
    class TaskWorker < TupleSpaceClient
      set_agent_type :task_worker

      class UnknownRuleError < StandardError
        def initialize(task)
          @task = task
        end

        def message
          "Unknown rule in the task of %s." % @task.inspect
        end
      end

      class Restart < StandardError
      end

      @mutex = Mutex.new

      # Return default number of running task workers in this machine.
      #
      # @return [Integer]
      #   default number
      def self.default_number
        [Util::CPU.core_number - 1, 1].max
      end

      # Start a task worker agent on a different process.
      # @param [Pione::Front::BasicFront] front
      #   caller front server
      # @return [Thread]
      #   worker monitor thread
      def self.spawn(front, connection_id, features=nil)
        args = [
          "pione-task-worker",
          "--parent-front", Global.front.uri,
          "--connection-id", connection_id
        ]
        args << "--debug" if Pione.debug_mode?
        args << "--show-communication" if Global.show_communication
        args << "--features" << features if features
        pid = Process.spawn(*args)
        thread = Process.detach(pid)
        # connection check
        while thread.alive?
          break if front.task_worker_front_connection_id.include?(connection_id)
          sleep 0.1
        end
        # error check
        unless thread.alive?
          Process.abort("You cannot run pione-task-worker.")
        end
        return thread
      end

      define_state :task_waiting
      define_state :task_processing
      define_state :rule_loading
      define_state :task_executing
      define_state :data_outputing
      define_state :task_finishing

      define_state_transition :initialized => :task_waiting
      define_state_transition :task_waiting => :rule_loading
      define_state_transition :rule_loading => :task_executing
      define_state_transition :task_executing => :data_outputing
      define_state_transition :data_outputing => :task_finishing
      define_state_transition :task_finishing => lambda {|agent, result|
        agent.once ? :terminated : :task_waiting
      }

      define_exception_handler Restart => :task_waiting

      attr_reader :task
      attr_reader :rule
      attr_reader :handler_thread
      attr_reader :child_thread
      attr_reader :child_agent
      attr_accessor :once

      def descendant
        if @child_agent
          [@child_agent] + child_agent.descendant
        else
          []
        end
      end

      def action?
        @action == true
      end

      def flow?
        @flow == true
      end

      private

      # Creates a task worker agent.
      # @param  [TupleSpaceServer] tuple_space_server
      #   tuple space server
      # @param [Feature::Expr] features
      #   feature set
      def initialize(tuple_space_server, features=Model::Feature::EmptyFeature.new)
        raise ArgumentError.new(features) unless features.kind_of?(Model::Feature::Expr)
        @features = features
        super(tuple_space_server)

        # ENV
        @env = ENV.clone
      end

      # Transition method for the state +task_waiting+. The agent takes a +task+
      # tuple and writes a +working+ tuple.
      #
      # @return [Task]
      #   task tuple
      def transit_to_task_waiting
        task = take(Tuple[:task].new(features: @features))
        begin
          write(Tuple[:working].new(task.domain, task.digest))
          write(Tuple[:foreground].new(task.domain, task.digest))
        rescue Rinda::RedundantTupleError
          raise Restart.new
        end
        return task
      rescue DRb::DRbConnError, DRb::ReplyReaderThreadError => e
        # tuple space may be closed
        ErrorReport.warn("Disconnected in task wainting of task worker agent.", self, e, __FILE__, __LINE__)
        terminate
      end

      # Transition method for the state +rule_loading+.
      # @return [Array<Task, Rule>]
      #   task tuple and the rule
      def transit_to_rule_loading(task)
        rule = read!(Tuple[:rule].new(rule_path: task.rule_path))
        unless rule
          write(Tuple[:request_rule].new(task.rule_path))
          rule = read(Tuple[:rule].new(rule_path: task.rule_path))
        end
        return task, rule.content
      end

      # Transition method for the state +task_executing+.
      # @param [Task] task
      #   task tuple
      # @param [Rule] rule
      #   rule for processing the task
      # @return [Array<Task,RuleHandler,Array<Data>>]
      def transit_to_task_executing(task, rule)
        debug_message_begin("Start Task Execution #{rule.path} by worker(#{uuid})")

        handler = rule.make_handler(
          tuple_space_server,
          task.inputs,
          task.params,
          task.call_stack
        )
        handler.setenv(ENV)
        @__result_task_execution__ = nil

        @handler_thread = Thread.new do
          @__result_task_execution__ = handler.handle
        end

        # make sub workers if flow rule
        @child_thread = Thread.new do
          if rule.flow?
            @flow = true
            @child_agent = nil
            while @handler_thread.alive? do
              if @child_agent.nil? or not(@child_agent.running_thread.alive?)
                debug_message "+++ Create Sub Task worker +++"
                @child_agent = self.class.new(tuple_space_server, @features)
                @child_agent.once = true

                Log::CreateChildTaskWorkerProcessRecord.new.tap do |record|
                  record.parent = uuid
                  record.child = @child_agent.uuid

                  with_process_log(record) do
                    take!(Tuple[:foreground].new(task.domain, nil))
                    @child_agent.start
                  end
                end
              else
                tail = descendant.last
                if tail.action?
                  tail.running_thread.join
                else
                  sleep 1
                end
              end
            end
            write(Tuple[:foreground].new(task.domain, task.digest))
          end

          if rule.action?
            @action = true
          end
        end

        # sleep until execution thread will be terminated
        @handler_thread.join
        @child_thread.join

        @flow = nil
        @action = nil

        # remove the working tuple
        take!(Tuple[:working].new(task.domain, nil))

        debug_message_end "End Task Execution #{rule.path} by worker(#{uuid})"

        return task, rule, handler, @__result_task_execution__
      end

      # State data_outputing.
      # @param task [Task]
      #   task tuple
      # @param rule [Rule]
      #   rule model
      # @param [RuleHandler] handler
      #   rule handler
      # @param [Array<Data>] result
      #   result data tuples
      # @return [Array<Task,RuleHandler>]
      def transit_to_data_outputing(task, rule, handler, result)
        # output data
        result.flatten.each do |output|
          begin
            write(output)
          rescue Rinda::RedundantTupleError
            # ignore
          end
        end
        return task, handler
      end

      # State task_finishing.
      # @param [Task] task
      #   task tuple
      # @param [RuleHandler] handler
      #   the handler
      # @return [void]
      def transit_to_task_finishing(task, handler)
        # put finished tuple
        finished = Tuple[:finished].new(
          handler.domain, :succeeded, handler.outputs, task.digest
        )
        write(finished)
        # log task process
        record = handler.task_process_record.merge(transition: "complete")
        process_log(record)

        # remove foreground
        take!(Tuple[:foreground].new(task.domain, nil))

        # terminate if the agent is child
        terminate if @once
      end

      # State error
      def transit_to_error(e)
        case e
        when UnknownRuleError
          # FIXME
          notify_exception(e)
        else
          super
        end
      end
    end

    set_agent TaskWorker
  end
end
