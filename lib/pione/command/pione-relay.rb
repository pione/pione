module Pione
  module Command
    class PioneRelay < FrontOwner
      set_program_name("pione-relay") do
        "--relay-port %s" % [@relay_port]
      end

      define_option("--realm name", "relay realm name for client authentification") do |name|
        Global.relay_realm = name
      end

      define_option("--relay-port port", "relay port") do |port|
        @relay_port = port
      end

      def initialize
        require 'drb/gw'
      end

      def validate_options
        abort("no realm name") unless Global.relay_realm
        abort("no relay port") unless @relay_port
      end

      def create_front
        Front::RelayFront.new(self, nil)
      end

      def start
        puts DRb.front.uri
        DRb::DRbServer.new(
          "relay://localhost:%s" % @relay_port,
          DRb::GW.new,
          {:SSLCertName => Global.relay_ssl_certname}
        )
        DRb.thread.join
      end
    end
  end
end
