module Pione
  module Global
    # This is a begin number of task-worker-front port range.
    define_external_item(:task_worker_front_port_range_begin, 50000)

    # This is an end number of task-worker-front port range.
    define_external_item(:task_worker_front_port_range_end, 54999)

    # This is task-worker-front port range.
    define_internal_item(:task_worker_front_port_range) do
      Range.new(
        Global.task_worker_front_port_range_begin,
        Global.task_worker_front_port_range_end
      )
    end
  end
end
