module Pione
  module Command
    # PioneRelay is a command for connecting relay server.
    class PioneRelay < BasicCommand
      #
      # basic informations
      #

      command_name("pione-relay") {|cmd| "relay-port: %s" % cmd.option[:relay_port]}
      command_banner "Run relay process for connecting between clients and brokers."
      command_front Front::RelayFront

      #
      # options
      #

      use_option :color
      use_option :debug
      use_option :communication_address

      define_option(:realm) do |item|
        item.long = "--realm name"
        item.desc = "set relay realm name for client authentification"
        item.action = lambda {|_, _, name| Global.relay_realm = name}
      end

      define_option(:relay_port) do |item|
        item.long = "--relay-port port"
        item.desc = "set relay port"
        item.default = Global.relay_port
        item.value = lambda {|port| port}
      end

      validate_option do |option|
        abort("error: no realm name") if Global.relay_realm.nil? or Global.relay_realm.empty?
        abort("error: no relay port") unless option[:relay_port]
      end

      #
      # command lifecycle: execution phase
      #

      execute :relay

      def execute_relay
        # wake up tuple space provider process
        Pione::TupleSpaceProvider.spawn

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
