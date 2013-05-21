module Pione
  module Util
    module IPAddress
      # Return my IP address that PIONE choosed.
      #
      # @return [String]
      #   my IP address
      def myself
        find.first
      end
      module_function :myself

      # Find IP address list in the machine. This list includes IPv4 addresses only.
      #
      # @return [Array<String>]
      #   IP addresses
      def find
        addrs = Socket.ip_address_list.select do |addr|
          addr.ipv4? and not(addr.ipv4_loopback?) and not(addr.ipv4_multicast?)
        end
        if not(addrs.empty?)
          privates = addrs.select{|addr| addr.ipv4_private?}
          not_privates = addrs - privates
          privates = privates.sort{|a,b| a.ip_address <=> b.ip_address}
          not_privates = not_privates.sort{|a, b| a.ip_address <=> b.ip_address}
          (privates + not_privates).map {|addr| addr.ip_address}
        else
          Socket.ip_address_list.select{|addr| addr.ipv4_loopback?}.map{|addr| addr.ip_address}
        end
      end
      module_function :find
    end
  end
end

