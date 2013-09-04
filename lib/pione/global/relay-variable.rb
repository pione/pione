module Pione
  module Global
    # relay user database path
    define_item(:relay_client_db_path, true) do
      Global.dot_pione_dir + "relay-client.db"
    end

    # relay client database object
    define_item(:relay_client_db, false) do
      Relay::RelayClientDB.new(Global.relay_client_db_path)
    end

    # relay account database path
    define_item(:relay_account_db_path, true) do
      Global.dot_pione_dir + "relay-account.db"
    end

    # relay account database object
    define_item(:relay_account_db, false) do
      Relay::RelayAccountDB.new(Global.relay_account_db_path)
    end

    # relay server's realm
    define_item(:relay_realm, true)

    # relay uri
    define_item(:relay_uri, false)

    # relay port
    define_item(:relay_port, true, 56001)

    # certname for relay server
    define_item(:relay_ssl_certname, true, [["CN", "localhost.localhost"]])

    # relay-front port range begin
    define_item(:relay_front_port_range_begin, true, 44000)

    # relay-front port range end
    define_item(:relay_front_port_range_end, true, 44999)

    # relay-front port range
    define_item(:relay_front_port_range, false) do
      Range.new(
        Global.relay_front_port_range_begin,
        Global.relay_front_port_range_end
      )
    end

    # relay-proxy port range begin
    define_item(:relay_proxy_port_range_begin, true, 45000)

    # relay-proxy port range end
    define_item(:relay_proxy_port_range_end, true, 45999)

    # relay-proxy port range
    define_item(:relay_proxy_port_range, false) do
      Range.new(
        Global.relay_proxy_port_range_begin,
        Global.relay_proxy_port_range_end
      )
    end

    # relay-client authentication timeout second
    define_item(:relay_client_auth_timeout_sec, true, 5)

    # relay tuple space server
    define_item(:relay_tuple_space_server, false)

    # relay-transmitter proxy side port range begin
    define_item(:relay_transmitter_proxy_side_port_begin, true, 46000)

    # relay-transmitter proxy side port range end
    define_item(:relay_transmitter_proxy_side_port_end, true, 46999)

    # relay-transmitter proxy side port range
    define_item(:relay_transmitter_proxy_side_port_range, false) do
      Range.new(
        Global.relay_transmitter_proxy_side_port_begin,
        Global.relay_transmitter_proxy_side_port_end
      )
    end

    # relay-receiver
    define_item(:relay_receiver, false)
  end
end
