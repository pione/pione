module Pione
  module Global
    # client-front port range begin
    define_external_item(:client_front_port_range_begin, 40000)

    # client-front port range end
    define_external_item(:client_front_port_range_end, 40999)

    # client-front port range
    define_internal_item(:client_front_port_range) do
      Range.new(
        Global.client_front_port_range_begin,
        Global.client_front_port_range_end
      )
    end
  end
end
