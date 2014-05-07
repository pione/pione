module Pione
  module Global
    # This is a begin number of port range for pione-interactive's front.
    define_external_item(:interactive_front_port_range_begin) do |item|
      item.desc = "start port number of interactive front"
      item.init = 40900
    end

    # This is an end number of port range for pione-interactive's front.
    define_external_item(:interactive_front_port_range_end) do |item|
      item.desc = "end port number of interactive front"
      item.init = 40999
    end

    # This is port range for pione-interactive's front.
    define_computed_item(:interactive_front_port_range, [:interactive_front_port_range_begin, :interactive_front_port_range_end]) do |item|
      item.desc = "port range of interactive front"
      item.define_updater do
        Range.new(
          Global.interactive_front_port_range_begin,
          Global.interactive_front_port_range_end
        )
      end
    end
  end
end
