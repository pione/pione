module Pione
  module Relay
    # RelaySocket is connection layer between PIONE client and PIONE relay.
    class RelaySocket < DRb::DRbSSLSocket
      # AuthError is an error for relay authentication failure.
      class AuthError < Exception
        def initialize(name)
          @name = name
        end
      end

      # BadMessage is an error for protocol violation.
      class BadMessage < Exception; end

      def self.parse_uri(uri)
        if uri =~ /^relay:\/\/(.*?):(\d+)(\?(.*))?$/
          host = $1
          port = $2.to_i
          option = $4
          [host, port, option]
        else
          raise(DRb::DRbBadScheme, uri) unless uri =~ /^relay:/
          raise(DRb::DRbBadURI, 'can\'t parse uri:' + uri)
        end
      end

      # Opens the socket on a client side.
      def self.open(uri, config)
        host, port, = parse_uri(uri)
        host.untaint
        port.untaint
        soc = TCPSocket.open(host, port)
        ssl_conf = DRb::DRbSSLSocket::SSLConfig.new(config)
        ssl_conf.setup_ssl_context
        ssl = ssl_conf.connect(soc)

        # auth like HTTP's digest method
        begin
          realm = ssl.gets.chomp
          uuid = ssl.gets.chomp
          name, digest = Global.relay_account_db[realm] || (raise AuthError.new(nil))
          response = "%s:%s" % [name, Digest::SHA512.hexdigest("%s:%s" % [uuid, digest])]
          ssl.puts(response)
          ssl.gets
        rescue
          raise AuthError.new(name)
        end

        self.new(uri, ssl, ssl_conf, true)
      end

      # Opens relay server port for clients.
      # @api private
      def self.open_server(uri, config)
        uri = 'relay://:0' unless uri
        host, port, = parse_uri(uri)
        if host.size == 0
          host = getservername
          soc = open_server_inaddr_any(host, port)
        else
          soc = TCPServer.open(host, port)
        end
        port = soc.addr[1] if port == 0
        @uri = "relay://#{host}:#{port}"

        ssl_conf = DRb::DRbSSLSocket::SSLConfig.new(config)
        ssl_conf.setup_certificate
        ssl_conf.setup_ssl_context

        self.new(@uri, soc, ssl_conf, false)
      end

      def self.uri_option(uri, config)
        host, port, option = parse_uri(uri)
        return "relay://#{host}:#{port}", option
      end

      # Accepts clients on server side.
      # @api private
      def accept
        begin
          while true
            soc = @socket.accept
            break if (@acl ? @acl.allow_socket?(soc) : true)
            soc.close
          end
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
            self.class.new(uri, ssl, @config, true)
          else
            raise BadMessage
          end
        rescue OpenSSL::SSL::SSLError
          warn("#{__FILE__}:#{__LINE__}: warning: #{$!.message} (#{$!.class})") if @config[:verbose]
          retry
        rescue AuthError, BadMessage
          soc.close
          retry
        end
      end
    end

    # install the protocol
    ::DRb::DRbProtocol.add_protocol(RelaySocket)
  end
end
