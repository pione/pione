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
      define_state_transition :task_executing => :data_outputing
      define_state_transition :data_outputing => :task_finishing
      define_state_transition :task_finishing => :task_waiting
      define_exception_handler :error

      private

      # State initialized.
      def transit_to_initialized
        hello
      end

      # State task_waiting.
      def transit_to_task_waiting
        puts "WORKER ==> waiting"
        task = take(Tuple[:task].any)
        puts "==> waaaaaaaaaaaaaaaaaaaaaaaaaa"
        return task
      end

      # State task_processing.
      def transit_to_task_processing(task)
        puts "WORKER ==> task_processing"
        if InnocentWhite.debug_mode?
          msg = "is processing the task #{task.module_path}(#{task.inputs.join(',')})"
          log(:debug, msg)
        end
        return task
      end

      # State module_loading.
      def transit_to_module_loading(task)
        puts "WORKER ==> module_loading"
        rule =
          begin
            read(Tuple[:rule].new(rule_path: task.rule_path), true)
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
        puts "WORKER ==> process_info_loading"
        return task, rule, read(Tuple[:process_info].any)
      end

      # State task_executing.
      def transit_to_task_executing(task, rule, process_info)
        puts "WORKER ==> task_executing"
        opts ={process_name: process_info.name, process_id: process_info.process_id}
        base_uri = read(Tuple[:base_uri].any).uri
        handler = rule.content.make_handler(base_uri,
                                            task.inputs,
                                            task.params,
                                            opts)
        result = handler.execute(get_tuple_space_server)
        return task, handler, result
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
        finished = Tuple[:finished].new(handler.domain, handler.task_id, :succeeded)
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
