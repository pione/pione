module Pione
  module Global
    define_external_item(:task_worker_broker_front_start_port) do |item|
      item.desc = "start port number for front server of `task-worker-broker`"
      item.init = 41000
      item.type = :integer
    end

    define_external_item(:task_worker_broker_front_end_port) do |item|
      item.desc = "end port number for front server of `task-worker-broker`"
      item.init = 41099
      item.type = :integer
    end

    define_computed_item(:task_worker_broker_front_port_range, [:broker_front_port_range_begin, :broker_front_port_range_end]) do |item|
      item.desc = "port range for front server of `task-worker-broker`"
      item.define_updater do
        start_port = Global.task_worker_broker_front_start_port
        end_port = Global.task_worker_broker_front_end_port

        Range.new(start_port, end_port)
      end
    end

    define_external_item(:task_worker_provider) do |item|
      item.desc = "provider method of `task-worker-broker`"
      item.init = "Pione::TaskWorkerBroker::EasyProvider"
      item.define_updater {|val| eval(val)}
    end

    define_external_item(:task_worker_broker_short_sleep_time) do |item|
      item.desc = "short sleep time for task worker broker"
      item.init = 1
      item.type = :positive_integer
    end

    define_external_item(:task_worker_broker_long_sleep_time) do |item|
      item.desc = "long sleep time for task worker broker"
      item.init = 3
      item.type = :positive_integer
    end
  end
end
