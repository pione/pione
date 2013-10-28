module Pione
  module Global
    # relay user database path
    define_internal_item(:relay_client_db_path) do |item|
      item.desc = "relay client database path"
      item.define_updater {Global.dot_pione_dir + "relay-client.db"}
    end

    # relay client database object
    define_computed_item(:relay_client_db, [:relay_client_db_path]) do |item|
      item.desc = "relay client database object"
      item.define_updater do
        Relay::RelayClientDB.new(Global.relay_client_db_path)
      end
    end

    # relay account database path
    define_external_item(:relay_account_db_path) do |item|
      item.desc = "relay account database path"
      item.define_updater do
        Global.dot_pione_dir + "relay-account.db"
      end
    end

    # relay account database object
    define_computed_item(:relay_account_db, [:relay_account_db_path]) do |item|
      item.desc = "relay account database object"
      item.define_updater do
        Relay::RelayAccountDB.new(Global.relay_account_db_path)
      end
    end

    # relay server's realm
    define_external_item(:relay_realm) do |item|
      item.desc = "relay server's realm"
    end

    # relay uri
    define_internal_item(:relay_uri) do |item|
      item.desc = "relay URI"
    end

    # relay port
    define_external_item(:relay_port) do |item|
      item.desc = "relay port"
      item.type = :integer
      item.init = 56001
    end

    # certname for relay server
    define_internal_item(:relay_ssl_certname) do |item|
      item.desc = "certname for relay server"
      item.init = [["CN", "localhost.localhost"]]
    end

    # relay-front port range begin
    define_external_item(:relay_front_port_range_begin) do |item|
      item.desc = "start port number of relay front"
      item.type = :integer
      item.init = 44000
    end

    # relay-front port range end
    define_external_item(:relay_front_port_range_end) do |item|
      item.desc = "end port number of relay front"
      item.type = :integer
      item.init = 44999
    end

    # relay-front port range
    define_computed_item(:relay_front_port_range,
      [:relay_front_port_range_begin, :relay_front_port_range_end]) do |item|
      item.desc = "port range of relay front"
      item.define_updater do
        Range.new(
          Global.relay_front_port_range_begin,
          Global.relay_front_port_range_end
        )
      end
    end

    # relay-proxy port range begin
    define_external_item(:relay_proxy_port_range_begin) do |item|
      item.desc = "start port number of relay proxy"
      item.type = :integer
      item.init = 45000
    end

    # relay-proxy port range end
    define_external_item(:relay_proxy_port_range_end) do |item|
      item.desc = "end port number of relay proxy"
      item.type = :integer
      item.init = 45999
    end

    # relay-proxy port range
    define_computed_item(:relay_proxy_port_range,
      [:relay_proxy_port_range_begin, :relay_proxy_port_range_end]) do |item|
      item.desc = "port range of relay proxy"
      item.define_updater do
        Range.new(
          Global.relay_proxy_port_range_begin,
          Global.relay_proxy_port_range_end
        )
      end
    end

    # relay-client authentication timeout second
    define_external_item(:relay_client_auth_timeout_sec) do |item|
      item.desc = "relay-client authentication timeout second"
      item.type = :integer
      item.init = 5
    end

    # relay tuple space server
    define_internal_item(:relay_tuple_space_server) do |item|
      item.desc = "relay tuple space server"
    end

    # relay-transmitter proxy side port range begin
    define_external_item(:relay_transmitter_proxy_side_port_begin) do |item|
      item.desc = "start port number of relay transmitter"
      item.type = :integer
      item.init = 46000
    end

    # relay-transmitter proxy side port range end
    define_external_item(:relay_transmitter_proxy_side_port_end) do |item|
      item.desc = "end port number of relay transmitter"
      item.type = :integer
      item.init = 46999
    end

    # relay-transmitter proxy side port range
    define_computed_item(:relay_transmitter_proxy_side_port_range,
      [:relay_transmitter_proxy_side_port_begin, :relay_transmitter_proxy_side_port_end]) do |item|
      item.desc = "port range of relay transmitter"
      item.define_updater do
        Range.new(
          Global.relay_transmitter_proxy_side_port_begin,
          Global.relay_transmitter_proxy_side_port_end
        )
      end
    end

    # relay-receiver
    define_internal_item(:relay_receiver) do |item|
      item.desc = "realy receiver"
    end
  end
end
