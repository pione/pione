module Pione
  module Global
    # relay user database path
    define_external_item(:relay_client_db_path) do
      Global.dot_pione_dir + "relay-client.db"
    end

    # relay client database object
    define_internal_item(:relay_client_db) do
      Relay::RelayClientDB.new(Global.relay_client_db_path)
    end

    # relay account database path
    define_external_item(:relay_account_db_path) do
      Global.dot_pione_dir + "relay-account.db"
    end

    # relay account database object
    define_internal_item(:relay_account_db) do
      Relay::RelayAccountDB.new(Global.relay_account_db_path)
    end

    # relay server's realm
    define_external_item(:relay_realm)

    # relay uri
    define_internal_item(:relay_uri)

    # relay port
    define_external_item(:relay_port, 56001)

    # certname for relay server
    define_external_item(:relay_ssl_certname, [["CN", "localhost.localhost"]])

    # relay-front port range begin
    define_external_item(:relay_front_port_range_begin, 44000)

    # relay-front port range end
    define_external_item(:relay_front_port_range_end, 44999)

    # relay-front port range
    define_internal_item(:relay_front_port_range) do
      Range.new(
        Global.relay_front_port_range_begin,
        Global.relay_front_port_range_end
      )
    end

    # relay-proxy port range begin
    define_external_item(:relay_proxy_port_range_begin, 45000)

    # relay-proxy port range end
    define_external_item(:relay_proxy_port_range_end, 45999)

    # relay-proxy port range
    define_internal_item(:relay_proxy_port_range) do
      Range.new(
        Global.relay_proxy_port_range_begin,
        Global.relay_proxy_port_range_end
      )
    end

    # relay-client authentication timeout second
    define_external_item(:relay_client_auth_timeout_sec, 5)

    # relay tuple space server
    define_internal_item(:relay_tuple_space_server)

    # relay-transmitter proxy side port range begin
    define_external_item(:relay_transmitter_proxy_side_port_begin, 46000)

    # relay-transmitter proxy side port range end
    define_external_item(:relay_transmitter_proxy_side_port_end, 46999)

    # relay-transmitter proxy side port range
    define_internal_item(:relay_transmitter_proxy_side_port_range) do
      Range.new(
        Global.relay_transmitter_proxy_side_port_begin,
        Global.relay_transmitter_proxy_side_port_end
      )
    end

    # relay-receiver
    define_internal_item(:relay_receiver)
  end
end
