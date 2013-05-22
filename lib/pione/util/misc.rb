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
    end

    extend Misc
  end
end
