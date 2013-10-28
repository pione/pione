module Pione
  module Global
    # This is a begin number of port range for client's front.
    define_external_item(:client_front_port_range_begin) do |item|
      item.desc = "start port number of client front"
      item.init = 40000
    end

    # This is an end number of port range for client's front.
    define_external_item(:client_front_port_range_end) do |item|
      item.desc = "end port number of client front"
      item.init = 40099
    end

    # This is port range for client's front.
    define_computed_item(:client_front_port_range, [:client_front_port_range_begin, :client_front_port_range_end]) do |item|
      item.desc = "port range of broker front"
      item.define_updater do
        Range.new(
          Global.client_front_port_range_begin,
          Global.client_front_port_range_end
        )
      end
    end
  end
end
