module Pione
  module Global
    #
    # provider & receiver
    #

    # presence port
    define_external_item(:presence_port, 56000)

    #
    # pione-tuple-space-provider
    #

    # tuple space provider uri
    define_internal_item(:tuple_space_provider_uri)

    # provider-front port range begin
    define_external_item(:tuple_space_provider_front_port_range_begin, 42000)

    # provider-front port range end
    define_external_item(:tuple_space_provider_front_port_range_end, 42999)

    # provider-front port range
    define_internal_item(:tuple_space_provider_front_port_range) do
      Range.new(
        Global.tuple_space_provider_front_port_range_begin,
        Global.tuple_space_provider_front_port_range_end
      )
    end

    # presence notification address
    define_external_item(:presence_notification_addresses) do
      [URI.parse("broadcast://%s:%s" % ["255.255.255.255", Global.presence_port])]
    end

    #
    # pione-tuple-space-receiver
    #

    # tuple space receiver uri
    define_internal_item(:tuple_space_receiver_uri)

    # receiver-front port range begin
    define_external_item(:tuple_space_receiver_front_port_range_begin, 43000)

    # receiver-front port range end
    define_external_item(:tuple_space_receiver_front_port_range_end, 43999)

    # receiver-front port range
    define_internal_item(:tuple_space_receiver_front_port_range) do
      Range.new(
        Global.tuple_space_receiver_front_port_range_begin,
        Global.tuple_space_receiver_front_port_range_end
      )
    end

    # disconnect time for tuple space receiver
    define_external_item(:tuple_space_receiver_disconnect_time, 180)
  end
end
