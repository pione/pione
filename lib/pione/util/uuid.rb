module Pione
  module Util
    module UUID
      # Generate random UUID as a string.
      #
      # @return [String]
      #   UUID string
      # @note
      #   we use uuidtools gem for generating UUID
      def generate
        UUIDTools::UUID.random_create.to_s
      end
      module_function :generate

      # Generate random UUID as an iteger.
      #
      # @return [Integer]
      #   UUID integer
      # @note
      #   we use uuidtools gem for generating UUID
      def generate_int
        UUIDTools::UUID.random_create.to_i
      end
      module_function :generate_int
    end
  end
end

