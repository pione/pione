module Pione
  module Global
    # broker-front port range begin
    define_external_item(:broker_front_port_range_begin) do |item|
      item.desc = "start port number of broker front"
      item.init = 41000
    end

    # broker-front port range end
    define_external_item(:broker_front_port_range_end) do |item|
      item.desc = "end port number of broker front"
      item.init = 41099
    end

    # broker-front port range
    define_computed_item(:broker_front_port_range, [:broker_front_port_range_begin, :broker_front_port_range_end]) do |item|
      item.desc = "port range of broker front"
      item.define_updater do
        Range.new(
          Global.broker_front_port_range_begin,
          Global.broker_front_port_range_end
        )
      end
    end

    # balancer method
    define_external_item(:broker_task_worker_balancer) do |item|
      item.desc = "balancer method of task worker broker"
      item.init = "Pione::Agent::EasyTaskWorkerBalancer"
      item.define_updater {|val| eval(val)}
    end
  end
end
