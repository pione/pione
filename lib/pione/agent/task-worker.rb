require 'pione/common'
require 'pione/agent'

module Pione
  module Agent
    class TaskWorker < TupleSpaceClient
      set_agent_type :task_worker

      class UnknownRuleError < StandardError
        def initialize(task)
          @task = task
        end

        def message
          "Unknown rule in the task of #{@task.inspect}."
        end
      end

      define_state :task_waiting
      define_state :task_processing
      define_state :rule_loading
      define_state :task_executing
      define_state :data_outputing
      define_state :task_finishing

      define_state_transition :initialized => :task_waiting
      define_state_transition :task_waiting => :task_processing
      define_state_transition :task_processing => :rule_loading
      define_state_transition :rule_loading => :task_executing
      define_state_transition :task_executing => :data_outputing
      define_state_transition :data_outputing => :task_finishing
      define_state_transition :task_finishing => lambda {|agent, result|
        agent.once ? :terminated : :task_waiting
      }

      attr_accessor :once

      private

      # Create a task worker agent.
      # [+tuple_space_server+] tuple space server
      # [+features+] feature set
      def initialize(tuple_space_server, features=Feature::EmptyFeature.new)
        raise ArgumentError.new(features) unless features.kind_of?(Feature::Expr)
        @features = features
        super(tuple_space_server)

        # ENV
        @env = ENV.clone
      end

      # Transition method for the state +task_waiting+. The agent takes a +task+
      # tuple and writes a +working+ tuple.
      def transit_to_task_waiting
        task = take(Tuple[:task].new(features: @features))
        write(Tuple[:working].new(task.domain))
        return task
      end

      # Transition method for the state +task_processing+. The agent starts
      # processing to do the task.
      def transit_to_task_processing(task)
        log do |msg|
          msg.add_record(agent_type, "action", "process_rule")
          msg.add_record(agent_type, "object", task)
        end
        return task
      end

      # Transition method for the state +rule_loading+.
      def transit_to_rule_loading(task)
        rule =
          begin
            read(Tuple[:rule].new(rule_path: task.rule_path), 0)
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

      # State task_executing.
      def transit_to_task_executing(task, rule)
        debug_message ">>> Start Task Execution #{rule.rule_path} by worker(#{uuid})"

        handler = rule.make_handler(
          tuple_space_server,
          task.inputs,
          task.params
        )
        handler.setenv(ENV)
        @__result_task_execution__ = nil

        th = Thread.new do
          @__result_task_execution__ = handler.execute
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
              child.start
            else
              sleep 1
            end
          end
        end

        # Sleep unless execution thread will be terminated
        th.join

        take(Tuple[:working].new(task.domain), 0)

        debug_message ">>> End Task Execution #{rule.rule_path} by worker(#{uuid})"

        return task, handler, @__result_task_execution__
      end

      # State data_outputing.
      def transit_to_data_outputing(task, handler, result)
        result.each {|output| write(output)}
        return task, handler
      end

      # State task_finishing.
      def transit_to_task_finishing(task, handler)
        log do |msg|
          msg.add_record(agent_type, "action", "finished_task")
          msg.add_record(agent_type, "uuid", uuid)
          msg.add_record(agent_type, "object", task)
        end
        finished = Tuple[:finished].new(handler.domain, :succeeded, handler.outputs)
        write(finished)
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
