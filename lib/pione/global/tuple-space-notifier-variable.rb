module Pione
  module Global
    #
    # provider & receiver
    #

    # presence port
    define_external_item(:presence_port) do |item|
      item.desc = "presence port number"
      item.type = :integer
      item.init = 56000
    end

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

    # presence notification address
    define_external_item(:presence_notification_addresses) do |item|
      item.desc = "presence notification addresses"
      item.init = ["255.255.255.255:56000"]
      item.define_updater do |vals|
        vals.map {|val| val.is_a?(String) ? URI.parse("broadcast://%s" % val) : val}
      end
    end

    #
    # pione-tuple-space-receiver
    #

    # tuple space receiver uri
    define_internal_item(:tuple_space_receiver_uri) do |item|
      item.desc = "URI of tuple space receiver"
    end

    # receiver-front port range begin
    define_external_item(:tuple_space_receiver_front_port_range_begin) do |item|
      item.desc = "start port number of tuple space receiver front"
      item.type = :integer
      item.init = 43000
    end

    # receiver-front port range end
    define_external_item(:tuple_space_receiver_front_port_range_end) do |item|
      item.desc = "end port number of tuple space receiver front"
      item.type = :integer
      item.init = 43999
    end

    # receiver-front port range
    define_computed_item(:tuple_space_receiver_front_port_range,
      [:tuple_space_receiver_front_port_range_begin, :tuple_space_receiver_front_port_range_end]) do |item|
      item.desc = "port range of tuple space receiver front"
      item.define_updater do
        Range.new(
          Global.tuple_space_receiver_front_port_range_begin,
          Global.tuple_space_receiver_front_port_range_end
        )
      end
    end

    # disconnect time for tuple space receiver
    define_internal_item(:tuple_space_receiver_disconnect_time) do |item|
      item.desc = "tuple space receiver disconnect time"
      item.type = :integer
      item.init = 180
    end
  end
end
