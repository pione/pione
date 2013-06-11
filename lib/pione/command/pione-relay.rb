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
        use :color
        use :debug
        use :my_ip_address
        use :show_communication

        define(:realm) do |item|
          item.long = "--realm name"
          item.desc = "set relay realm name for client authentification"
          item.action = lambda {|_, name| Global.relay_realm = name}
        end

        define(:relay_port) do |item|
          item.long = "--relay-port port"
          item.desc = "set relay port"
          item.default = Global.relay_port
          item.value = lambda {|port| port}
        end

        validate do |option|
          abort("error: no realm name") if Global.relay_realm.nil? or Global.relay_realm.empty?
          abort("error: no relay port") unless option[:relay_port]
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
          "relay://:%s" % option[:relay_port],
          nil,
          {:SSLCertName => Global.relay_ssl_certname}
        )
        DRb.thread.join
      end
    end
  end
end
