module Pione
  module Util
    module Misc
      # Ignores all exceptions of the block execution.
      # @yield []
      #   target block
      # @return [void]
      def ignore_exception(&b)
        begin
          b.call
        rescue Exception
          # do nothing
        end
      end

      # Generates random UUID.
      # @return [String]
      #   generated UUID string
      # @note
      #   we use uuidtools gem for generating UUID
      def generate_uuid
        UUIDTools::UUID.random_create.to_s
      end

      def generate_uuid_int
        UUIDTools::UUID.random_create.to_i
      end

      # Returns the hostname of the machine.
      # @return [String]
      #   hostname
      def hostname
        Socket.gethostname
      end

      # Returns CPU core number. The number is based on +/proc/cpuinfo+. Platforms
      # that don't have cpuinfo returns 1.
      # @return [Integer]
      #    CPU core nunmber
      def core_number
        begin
          `cat /proc/cpuinfo | grep processor | wc -l`.to_i
        rescue
          1
        end
      end

      # Parses IP address string. Address string is written with port number.
      # @return [Array<String, Integer>]
      def parse_ip_address(s)
        ":"
      end

      def my_ip_address_list
        Socket.ip_address_list.select do |addr|
          addr.ipv4? and not(addr.ipv4_loopback?)
        end.map {|addr| addr.ip_address}
      end
    end

    extend Misc
  end
end
