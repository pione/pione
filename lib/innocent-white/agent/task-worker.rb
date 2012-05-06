require 'innocent-white/common'
require 'innocent-white/agent'
require 'innocent-white/rule'

module InnocentWhite
  module Agent
    class TaskWorker < Base
      set_agent_type :task_worker

      class UnknownTask < Exception; end

      define_state :process_info_loading
      define_state :task_waiting
      define_state :task_processing
      define_state :rule_loading
      define_state :task_executing
      define_state :data_outputing
      define_state :task_finishing

      define_state_transition :initialized => :task_waiting
      define_state_transition :task_waiting => :task_processing
      define_state_transition :task_processing => :rule_loading
      define_state_transition :rule_loading => :process_info_loading
      define_state_transition :process_info_loading => :task_executing
      define_state_transition :task_executing => :data_outputing
      define_state_transition :data_outputing => :task_finishing
      define_state_transition :task_finishing => lambda {|agent|
        agent.once ? :terminated : :task_waiting
      }

      attr_accessor :once

      private

      # State task_waiting.
      def transit_to_task_waiting
        return take(Tuple[:task].any)
      end

      # State task_processing.
      def transit_to_task_processing(task)
        log do |msg|
          msg.add_record(agent_type, "action", "process_rule")
          msg.add_record(agent_type, "object", task)
        end
        return task
      end

      # State rule_loading.
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
          return task, rule
        else
          raise UnkownTask.new(task)
        end
      end

      # State process_info_loading
      def transit_to_process_info_loading(task, rule)
        return task, rule, read(Tuple[:process_info].any)
      end

      # State task_executing.
      def transit_to_task_executing(task, rule, process_info)
        puts ">>> Start Task Execution by worker(#{@uuid})" if debug_mode?

        opts ={process_name: process_info.name, process_id: process_info.process_id}
        handler = rule.content.make_handler(tuple_space_server,
                                            task.inputs,
                                            task.params,
                                            opts)
        @__result_task_execution__ = nil

        th = Thread.new do
          @__result_task_execution__ = handler.execute
        end

        # make sub workers if flow rule
        if rule.content.flow?
          child = nil
          while th.alive? do
            if child.nil? or not(child.running_thread.alive?)
              puts "+++ Create Sub Task worker +++" if debug_mode?
              child = self.class.new(tuple_space_server)
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

        puts ">>> End Task Execution by worker(#{@uuid})" if debug_mode?

        return task, handler, @__result_task_execution__
      end

      # State data_outputing.
      def transit_to_data_outputing(task, handler, result)
        result.each do |domain, name, uri|
          write(Tuple[:data].new(domain: domain, name: name, uri: uri))
        end
        return task, handler
      end

      # State task_finishing.
      def transit_to_task_finishing(task, handler)
        finished = Tuple[:finished].new(handler.domain, :succeeded, handler.outputs)
        write(finished)
        terminate if @once
      end

      # State error
      def transit_to_error(e)
        case e
        when UnknownTask
          # FIXME
          notify_exception(e)
        else
          super
        end
      end

      advise :after, {
        :method => :transit_to_task_finishing,
        :method_options => [:private]
      } do |jp, agent, *args|
        task = args.first
        agent.log do |msg|
          msg.add_record(agent.agent_type, "action", "finished_task")
          msg.add_record(agent.agent_type, "uuid", agent.uuid)
          msg.add_record(agent.agent_type, "object", task)
        end
      end
    end

    set_agent TaskWorker
  end
end
