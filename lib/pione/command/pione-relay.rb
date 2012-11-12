module Pione
  module Command
    class PioneRelay < FrontOwnerCommand
      set_program_name("pione-relay") do
        "--relay-port %s" % [@relay_port]
      end

      set_program_message <<TXT
Runs relay process for connecting between clients and brokers.
TXT

      define_option("--realm name", "set relay realm name for client authentification") do |name|
        Global.relay_realm = name
      end

      define_option("--relay-port port", "set relay port") do |port|
        @relay_port = port
      end

      def initialize
        @relay_port = Global.relay_port
      end

      def validate_options
        abort("error: no realm name") if Global.relay_realm.nil? or Global.relay_realm.empty?
        abort("error: no relay port") unless @relay_port
      end

      def create_front
        Front::RelayFront.new(self)
      end

      def start
        # wake up tuple space provider process
        Pione::TupleSpaceProvider.instance

        puts DRb.front.uri
        DRb::DRbServer.new(
          "relay://:%s" % @relay_port,
          nil,
          {:SSLCertName => Global.relay_ssl_certname}
        )
        DRb.thread.join
      end
    end
  end
end
