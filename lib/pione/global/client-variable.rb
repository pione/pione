module Pione
  module Global
    # This is a begin number of port range for client's front.
    define_external_item(:client_front_port_range_begin, 40000)

    # This is an end number of port range for client's front.
    define_external_item(:client_front_port_range_end, 40099)

    # This is port range for client's front.
    define_computed_item(:client_front_port_range,
      [:client_front_port_range_begin, :client_front_port_range_end]) do
      Range.new(
        Global.client_front_port_range_begin,
        Global.client_front_port_range_end
      )
    end
  end
end
