require 'innocent-white'
require 'innocent-white/agent'
require 'innocent-white/rule'
require 'innocent-white/tuple'

module InnocentWhite
  module Agent
    class TaskWorker < Base
      set_agent_type :task_worker

      class UnknownTask < Exception; end

      define_state :initialized
      define_state :process_info_loading
      define_state :task_waiting
      define_state :task_processing
      define_state :module_loading
      define_state :task_executing
      define_state :data_outputing
      define_state :task_finishing
      define_state :terminated

      define_state_transition :initialized => :task_waiting
      define_state_transition :task_waiting => :task_processing
      define_state_transition :task_processing => :module_loading
      define_state_transition :module_loading => :process_info_loading
      define_state_transition :process_info_loading => :task_executing
      define_state_transition :task_excuteing => :task_outputing
      define_state_transition :task_outputing => :task_finished
      define_state_transition :task_finished => :task_waiting
      define_exception_handler :error

      private

      # State initialized.
      def transit_to_initialized
        hello
      end

      # State task_waiting.
      def transit_to_task_waiting
        return take(Tuple[:task].any)
      end

      # State task_processing.
      def transit_to_task_processing(task)
        if InnocentWhite.debug_mode?
          msg = "is processing the task #{task.module_path}(#{task.inputs.join(',')})"
          log(:debug, msg)
        end
        return task
      end

      # State module_loading.
      def transit_to_module_loading(task)
        rule =
          begin
            read(Tuple[:rule].new(rule_path: task.rule_path), 0)
          rescue Rinda::RequestExpiredError
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
        handler = rule.content.create_handler(task.inputs,
                                              task.params,
                                              process_info.name,
                                              process.process_id)
        result = handler.execute
        return task, handler, result
      end

      # State data_outputing.
      def transit_to_data_outputing(task, handler, result)
        result.each do |domain, name, uri|
          write(Tuple[:data].new(domain: domain, name: name, uri: uri))
        end
        return task
      end

      # State task_finishing.
      def transit_to_task_finishing(task)
        finished = Tuple[:finished].new(uuid: task.uuid, status: :succeeded)
        write(finished)
      end

      def transit_to_error(e)
        case e
        when UnknownTask
          # FIXME
          notify_exception(e)
        else
          notify_exception(e)
          terminate
        end
      end

      # State terminated
      def transit_to_terminated
        bye
        puts "task-worker: stop" if InnocentWhite.debug_mode?
      end
    end

    set_agent TaskWorker
  end
end
