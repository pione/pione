require 'innocent-white/agent'
require 'innocent-white/process-handler'

module InnocentWhite
  module Agent
    class TaskWorker < Base
      set_agent_type :task_worker

      define_state(:initialized)
      define_state(:task_waiting)
      define_state(:task_processing)
      define_state(:module_loading)
      define_state(:task_executing)
      define_state(:data_outputing)
      define_state(:task_finishing)
      define_state(:stopped)

      define_state_transition_table {
        :initialized => :task_waiting,
        :task_waiting => :task_processing,
        :task_processing => :module_loading,
        :module_loading => :task_executing,
        :task_excuteing => :task_outputing,
        :task_outputing => :task_finished,
        :task_finished => :task_waiting
      }
      catch_exception :stopped

      private

      def transit_to_initialized
        hello
      end

      def transit_to_task_waiting
        take(Tuple[:task].any)
      end

      def transit_to_task_processing(task)
        log(:debug, "is processing the task for #{path}(#{inputs.join(',')})")
        return task
      end

      def transit_to_module_loading(task)
        mod = Tuple[:module].new(path: task.name, statue: :known)
        return task, read(mod)
      end

      def transit_to_task_executed(task, process_class)
        handler = process_class.content.new(inputs)
        result = handler.execute
        return task, handler, result
      end

      def transit_to_data_outputed(task, handler, result)
        # FIXME: handle raw data only now
        data = Tuple[:data].new(data_type: :raw,
                                name: handler.outputs.first,
                                raw: result)
        write(data)
        return task
      end

      def transit_to_task_finished(task)
        finished = Tuple[:finished].new(uuid: task.uuid, status: :succeeded)
        write(finished)
      end

      def transit_to_stopped
        bye
        puts "task-worker: stop" if InnocentWhite.debug_mode?
      end
    end

    set_agent TaskWorker
  end
end
