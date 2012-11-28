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

      @monitor = Monitor.new

      # Start a task worker agent on a different process.
      # @param [Pione::Front::BasicFront] front
      #   caller front server
      # @return [Thread]
      #   worker monitor thread
      def self.spawn(front, connection_id)
        @monitor.synchronize do
          args = [
            "pione-task-worker",
            "--parent-front", Global.front.uri,
            "--connection-id", connection_id
          ]
          args << "--debug" if Pione.debug_mode?
          args << "--show-communication" if Global.show_communication
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

      attr_accessor :once

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
      # @return [Task]
      #   task tuple
      def transit_to_task_waiting
        task = take(Tuple[:task].new(features: @features))
        write(Tuple[:working].new(task.domain, task.digest))
        write(Tuple[:foreground].new(task.domain, task.digest))
        return task
      end

      # Transition method for the state +rule_loading+.
      # @return [Array<Task, Rule>]
      #   task tuple and the rule
      def transit_to_rule_loading(task)
        rule =
          begin
            read0(Tuple[:rule].new(rule_path: task.rule_path))
          rescue Rinda::RequestExpiredError
            log do |msg|
              msg.add_record(agent_type, "action", "request_rule")
              msg.add_record(agent_type, "object", task.rule_path)
            end
            write(Tuple[:request_rule].new(task.rule_path))
            read(Tuple[:rule].new(rule_path: task.rule_path))
          end
        if rule.status == :known
          return task, rule.content
        else
          raise UnknownRuleError.new(task)
        end
      end

      # Transition method for the state +task_executing+.
      # @param [Task] task
      #   task tuple
      # @param [Rule] rule
      #   rule for processing the task
      # @return [Array<Task,RuleHandler,Array<Data>>]
      def transit_to_task_executing(task, rule)
        debug_message_begin("Start Task Execution #{rule.rule_path} by worker(#{uuid})")

        handler = rule.make_handler(
          tuple_space_server,
          task.inputs,
          task.params,
          task.call_stack
        )
        handler.setenv(ENV)
        @__result_task_execution__ = nil

        th = Thread.new do
          @__result_task_execution__ = handler.handle
        end

        # make sub workers if flow rule
        if rule.flow?
          child = nil
          while th.alive? do
            if child.nil? or not(child.running_thread.alive?)
              debug_message "+++ Create Sub Task worker +++"
              child = self.class.new(tuple_space_server, @features)
              child.once = true
              log do |msg|
                msg.add_record(agent_type, "action", "create_sub_task_worker")
                msg.add_record(agent_type, "uuid", uuid)
                msg.add_record(agent_type, "object", child.uuid)
              end
              take0(Tuple[:foreground].new(task.domain, nil)) rescue true
              child.start
            else
              sleep 1
            end
          end
          write(Tuple[:foreground].new(task.domain, task.digest))
        end

        # sleep until execution thread will be terminated
        th.join

        # remove the working tuple
        take0(Tuple[:working].new(task.domain, nil))

        debug_message_end "End Task Execution #{rule.rule_path} by worker(#{uuid})"

        return task, handler, @__result_task_execution__
      end

      # State data_outputing.
      # @param [Task] task
      #   task tuple
      # @param [RuleHandler] handler
      #   rule handler
      # @param [Array<Data>] result
      #   result data tuples
      # @return [Array<Task,RuleHandler>]
      def transit_to_data_outputing(task, handler, result)
        result.flatten.each {|output| write(output)}
        return task, handler
      end

      # State task_finishing.
      # @param [Task] task
      #   task tuple
      # @param [RuleHandler] handler
      #   the handler
      # @return [void]
      def transit_to_task_finishing(task, handler)
        log do |msg|
          msg.add_record(agent_type, "action", "finished_task")
          msg.add_record(agent_type, "uuid", uuid)
          msg.add_record(agent_type, "object", task)
        end
        finished = Tuple[:finished].new(
          handler.domain, :succeeded, handler.outputs, task.digest
        )
        write(finished)
        take0(Tuple[:foreground].new(task.domain, nil))
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
