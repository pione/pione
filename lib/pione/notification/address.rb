module Pione
  module Notification
    # Nofitication::Address provides utility methods for notification addresses.
    module Address
      MULTICAST_ADDRESS = IPAddr.new("224.0.0.0/4")

      class << self
        # Convert the target address to URI.
        def target_address_to_uri(address)
          address_to_uri(
            address,
            Global.default_notification_target_host,
            Global.default_notification_target_port
          )
        end

        # Convert the receiver address to URI.
        def receiver_address_to_uri(address)
          address_to_uri(
            address,
            Global.default_notification_receiver_host,
            Global.default_notification_receiver_port
          )
        end

        # Return default target address.
        def default_target_address
          host_and_port_to_uri(
            Global.default_notification_target_host,
            Global.default_notification_target_port
          )
        end

        # Return default receiver address.
        def default_receiver_address
          host_and_port_to_uri(
            Global.default_notification_receiver_host,
            Global.default_notification_receiver_port
          )
        end

        private

        # Convert the address to URI.
        def address_to_uri(address, default_host, default_port)
          uri = URI.parse(address)
          unless ["pnb", "pnm", "pnu"].include?(uri.scheme)
            raise URI::InvalidURIError
          end
          uri.host = default_host if uri.host == "."
          uri.port = default_port if uri.port.nil?
          return uri
        rescue URI::InvalidURIError
          if port_only?(address)
            return port_to_uri(default_host, address)
          end

          if host_only?(address)
            return host_to_uri(default_port, address)
          end

          host_and_port_to_uri(*address.split(":"))
        end

        # Return true if the address contains port only.
        def port_only?(address)
          address[0] == ":"
        end

        # Return true if the address conatains host only.
        def host_only?(address)
          not(address.include?(":"))
        end

        # Return true if the host is a multicast address.
        def multicast?(host)
          _host = IPSocket.getaddress(host)
          MULTICAST_ADDRESS.include?(_host)
        end

        # Convert the host to URI. The scheme assumes "pnb" excluding multicast
        # addresses.
        def host_to_uri(default_port, host)
          scheme = multicast?(host) ? "pnm" : "pnb"
          URI.parse("%s://%s:%s" % [scheme, host, default_port])
        end

        # Convert the port to URI. The scheme assumes "pnb" excluding multicast
        # addresses.
        def port_to_uri(default_host, address)
          scheme = multicast?(default_host) ? "pnm" : "pnb"
          URI.parse("%s://%s:%s" % [scheme, default_host, address.sub(":", "")])
        end

        # Convert the host and port to URI. The scheme assumes "pnb" excluding
        # multicast addresses.
        def host_and_port_to_uri(host, port)
          scheme = multicast?(host) ? "pnm" : "pnb"
          URI.parse("%s://%s:%s" % [scheme, host, port])
        end
      end
    end
  end
end
