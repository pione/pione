module Pione
  module Command
    # PioneRelay is a command for connecting relay server.
    class PioneRelay < FrontOwnerCommand
      define_info do
        set_name "pione-relay"
        set_tail {|cmd| "--relay-port %s" % cmd.option[:relay_port]}
        set_banner "Run relay process for connecting between clients and brokers."
      end

      define_option do
        default :relay_port, Global.relay_port

        option("--realm name", "set relay realm name for client authentification") do |data, name|
          Global.relay_realm = name
        end

        option("--relay-port port", "set relay port") do |data, port|
          data[:relay_port] = port
        end

        validate do |data|
          abort("error: no realm name") if Global.relay_realm.nil? or Global.relay_realm.empty?
          abort("error: no relay port") unless data[:relay_port]
        end
      end

      def create_front
        Front::RelayFront.new(self)
      end

      start do
        # wake up tuple space provider process
        Pione::TupleSpaceProvider.instance

        puts DRb.front.uri
        DRb::DRbServer.new(
          "relay://:%s" % data[:relay_port],
          nil,
          {:SSLCertName => Global.relay_ssl_certname}
        )
        DRb.thread.join
      end
    end
  end
end
