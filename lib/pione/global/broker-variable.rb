module Pione
  module Global
    # broker-front port range begin
    define_item(:broker_front_port_range_begin, true, 41000)

    # broker-front port range end
    define_item(:broker_front_port_range_end, true, 41999)

    # broker-front port range
    define_item(:broker_front_port_range, false) do
      Range.new(
        Global.broker_front_port_range_begin,
        Global.broker_front_port_range_end
      )
    end

    # balancer method
    define_item(:broker_task_worker_balancer, true) {Agent::EasyTaskWorkerBalancer}
  end
end
