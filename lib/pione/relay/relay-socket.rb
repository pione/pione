module Pione
  module Relay
    # RelaySocket is connection layer between PIONE client and PIONE relay.
    class RelaySocket < DRb::DRbSSLSocket
      # AuthError is an error for relay authentication failure.
      class AuthError < StandardError; end

      # ProxyError is raised when proxy server cannot start.
      class ProxyError < StandardError; end

      # BadMessage is an error for protocol violation.
      class BadMessage < Exception; end

      def self.parse_uri(uri)
        if uri =~ /^relay:\/\/(.*?)(:(\d+))?(\?(.*))?$/
          host = $1
          port = $3 ? $3.to_i : Global.relay_port
          option = $5
          return host, port, option
        else
          raise DRb::DRbBadScheme.new(uri) unless uri =~ /^relay:/
          raise DRb::DRbBadURI.new('can\'t parse uri:' + uri)
        end
      end

      # Opens the socket on pione-client.
      def self.open(uri, config)
        host, port, option = parse_uri(uri)
        host.untaint
        port.untaint

        # make tcp connection with SSL
        soc = TCPSocket.open(host, port)
        ssl_conf = DRb::DRbSSLSocket::SSLConfig.new(config)
        ssl_conf.setup_ssl_context
        ssl = ssl_conf.connect(soc)

        if Global.show_communication
          puts "you connected relay socket to %s" % uri
        end

        # auth like HTTP's digest method
        begin
          Timeout.timeout(Global.relay_client_auth_timeout_sec) do
            realm = ssl.gets.chomp
            uuid = ssl.gets.chomp
            account = Global.relay_account_db[realm] || (raise AuthError.new("unknown realm: %s" % realm))
            name = account.name
            digest = account.digest
            response = "%s:%s" % [name, Digest::SHA512.hexdigest("%s:%s" % [uuid, digest])]
            ssl.puts(response)
            unless ssl.read(3).chomp == "OK"
              raise AuthError.new("authentication failed")
            end
          end
        rescue AuthError => e
          raise e
        rescue Timeout::Error
          raise AuthError.new("authentication timeout")
        end

        if Global.show_communication
          puts "you succeeded relay authentication: %s" % uri
        end

        # create receiver socket
        ReceiverSocket.table["%s:%s" % [host, port]] = ssl
        Global.relay_receiver = DRb::DRbServer.new(
          "receiver://%s:%s" % [host, port],
          Global.relay_tuple_space_server
        )

        # create an instance
        return self.new(uri, ssl, ssl_conf, true)
      end

      # Opens relay server port for clients.
      # @api private
      def self.open_server(uri, config)
        # parse URI
        uri = 'relay://:%s' % Global.relay_port unless uri
        host, port, option = parse_uri(uri)

        # rebuild URI
        if host.size == 0
          host = getservername
          soc = open_server_inaddr_any(host, port)
        else
          soc = TCPServer.open(host, port)
        end
        port = soc.addr[1] if port == 0
        new_uri = "relay://#{host}:#{port}"

        # prepare SSL
        ssl_conf = DRb::DRbSSLSocket::SSLConfig.new(config).tap do |conf|
          conf.setup_certificate
          conf.setup_ssl_context
        end

        # create instance
        self.new(new_uri, soc, ssl_conf, false)
      end

      def self.uri_option(uri, config)
        host, port, option = parse_uri(uri)
        return "relay://#{host}:#{port}", option
      end

      # Accepts clients on server side.
      # @api private
      def accept
        begin
          # accept loop
          while true
            soc = @socket.accept
            break if (@acl ? @acl.allow_socket?(soc) : true)
            soc.close
          end

          if Global.show_communication
            puts "someone connected to relay socket..."
          end

          # build ssl
          ssl = @config.accept(soc)

          # relay auth like HTTP's digest method
          ssl.puts(Global.relay_realm)
          uuid = Util.generate_uuid
          ssl.puts(uuid)
          if msg = ssl.gets
            name, digest = msg.chomp.split(":")
            unless Global.relay_client_db.auth(uuid, name, digest)
              raise AuthError.new(name)
            end
            ssl.puts "OK"

            if Global.show_communication
              puts "succeeded authentication for %s" % name
            end

            # setup transmitter_id
            transmitter_id = Util.generate_uuid

            # save ssl socket as receiver side with transmitter_id
            TransmitterSocket.receiver_socket[transmitter_id] = ssl

            # open and save tcp socket with transmitter_id
            Global.relay_transmitter_proxy_side_port_range.each do |port|
              begin
                tcp_socket = TCPServer.new("localhost", port)
                TransmitterSocket.proxy_socket[transmitter_id] = tcp_socket
                break
              rescue
              end
            end

            # create servers
            create_transmitter_server(transmitter_id)
            create_proxy_server(transmitter_id)

            # start to provide tuple space
            Global.relay_front.tuple_space_provider.tuple_space_server = @tuple_space_server

            # create instance
            self.class.new(uri, ssl, @config, true)
          else
            raise BadMessage
          end
        rescue OpenSSL::SSL::SSLError, AuthError, BadMessage => e
          soc.close
          if Global.show_communication
            puts "closed relay socket"
            puts "%s: %s" % [e.class, e.message]
            caller.each {|line| puts "    %s" % line}
          end
          retry
        end
      end

      # Creates a transmitter server with the relay socket.
      # @return [void]
      def create_transmitter_server(transmitter_id)
        uri = "transmitter://%s" % transmitter_id
        server = DRb::DRbServer.new(uri, Trampoline.new(uri, @config))
        if Global.show_communication
          puts "relay created the transmitter: %s" % server.uri
        end
        return server
      end

      # Creates a proxy server for brokers in LAN.
      def create_proxy_server(transmitter_id)
        transmitter = DRb::DRbObject.new_with_uri("transmitter://%s" % transmitter_id)
        Global.relay_proxy_port_range.each do |port|
          begin
            uri = "druby://localhost:%s" % port
            server = DRb::DRbServer.new(uri, transmitter)
            if Global.show_communication
              puts "relay created the proxy: %s" % server.uri
            end
            return server
          rescue
            next
          end
        end
        raise ProxyError.new("You cannot start relay proxy server.")
      end
    end

    # install the protocol
    DRb::DRbProtocol.add_protocol(RelaySocket)
  end
end
