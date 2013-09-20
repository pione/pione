module Pione
  module Global
    # broker-front port range begin
    define_external_item(:broker_front_port_range_begin, 41000)

    # broker-front port range end
    define_external_item(:broker_front_port_range_end, 41999)

    # broker-front port range
    define_internal_item(:broker_front_port_range) do
      Range.new(
        Global.broker_front_port_range_begin,
        Global.broker_front_port_range_end
      )
    end

    # balancer method
    define_external_item(:broker_task_worker_balancer) {Agent::EasyTaskWorkerBalancer}
  end
end
