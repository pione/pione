module Pione
  module Global
    #
    # provider & receiver
    #

    # presence port
    define_item(:presence_port, true, 56000)

    #
    # pione-tuple-space-provider
    #

    # tuple space provider uri
    define_item(:tuple_space_provider_uri, false)

    # provider-front port range begin
    define_item(:tuple_space_provider_front_port_range_begin, true, 42000)

    # provider-front port range end
    define_item(:tuple_space_provider_front_port_range_end, true, 42999)

    # provider-front port range
    define_item(:tuple_space_provider_front_port_range, false) do
      Range.new(
        Global.tuple_space_provider_front_port_range_begin,
        Global.tuple_space_provider_front_port_range_end
      )
    end

    # presence notification address
    define_item(:presence_notification_addresses, true) do
      [URI.parse("broadcast://%s:%s" % ["255.255.255.255", Global.presence_port])]
    end

    #
    # pione-tuple-space-receiver
    #

    # tuple space receiver uri
    define_item(:tuple_space_receiver_uri, false)

    # receiver-front port range begin
    define_item(:tuple_space_receiver_front_port_range_begin, true, 43000)

    # receiver-front port range end
    define_item(:tuple_space_receiver_front_port_range_end, true, 43999)

    # receiver-front port range
    define_item(:tuple_space_receiver_front_port_range, false) do
      Range.new(
        Global.tuple_space_receiver_front_port_range_begin,
        Global.tuple_space_receiver_front_port_range_end
      )
    end

    # disconnect time for tuple space receiver
    define_item(:tuple_space_receiver_disconnect_time, true, 180)
  end
end
