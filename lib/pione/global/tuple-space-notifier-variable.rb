module Pione
  module Global
    #
    # provider & receiver
    #

    #
    # pione-tuple-space-provider
    #

    # tuple space provider uri
    define_internal_item(:tuple_space_provider_uri) do |item|
      item.desc = "URI of uple space provider"
    end

    # provider-front port range begin
    define_external_item(:tuple_space_provider_front_port_range_begin) do |item|
      item.desc = "start port number of tuple space provider front"
      item.type = :integer
      item.init = 42000
    end

    # provider-front port range end
    define_external_item(:tuple_space_provider_front_port_range_end) do |item|
      item.desc = "start port number of tuple space provider front"
      item.type = :integer
      item.init = 42099
  end

    # provider-front port range
    define_internal_item(:tuple_space_provider_front_port_range,
      [:tuple_space_provider_front_port_range_begin, :tuple_space_provider_front_port_range_end]) do |item|
      item.desc = "port range of tuple space provider"
      item.define_updater do
        Range.new(
          Global.tuple_space_provider_front_port_range_begin,
          Global.tuple_space_provider_front_port_range_end
        )
      end
    end

    define_internal_item(:tuple_space_disconnection_time) do |item|
      item.desc = "tuple space disconnection time"
      item.type = :integer
      item.init = 60
    end
  end
end
