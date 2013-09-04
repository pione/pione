module Pione
  module Global
    # task-worker-front port range begin
    define_item(:task_worker_front_port_range_begin, true, 50000)

    # task-worker-front port range end
    define_item(:task_worker_front_port_range_end, true, 54999)

    # task-worker-front port range
    define_item(:task_worker_front_port_range, false) do
      Range.new(
        Global.task_worker_front_port_range_begin,
        Global.task_worker_front_port_range_end
      )
    end
  end
end
