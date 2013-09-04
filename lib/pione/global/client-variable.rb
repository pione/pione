module Pione
  module Global
    # client-front port range begin
    define_item(:client_front_port_range_begin, true, 40000)

    # client-front port range end
    define_item(:client_front_port_range_end, true, 40999)

    # client-front port range
    define_item(:client_front_port_range, false) do
      Range.new(
        Global.client_front_port_range_begin,
        Global.client_front_port_range_end
      )
    end
  end
end
