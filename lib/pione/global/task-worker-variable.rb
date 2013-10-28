module Pione
  module Global
    # This is a begin number of task-worker-front port range.
    define_external_item(:task_worker_front_port_range_begin) do |item|
      item.desc = "start port number of task worker front"
      item.type = :integer
      item.init = 50000
    end

    # This is an end number of task-worker-front port range.
    define_external_item(:task_worker_front_port_range_end) do |item|
      item.desc = "start port number of task worker front"
      item.type = :integer
      item.init = 50999
    end

    # This is task-worker-front port range.
    define_computed_item(:task_worker_front_port_range,
      [:task_worker_front_port_range_begin, :task_worker_front_port_range_end]) do |item|
      item.desc = "port range of task worker front"
      item.define_updater do
        Range.new(
          Global.task_worker_front_port_range_begin,
          Global.task_worker_front_port_range_end
        )
      end
    end
  end
end
