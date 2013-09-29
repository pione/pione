module Pione
  module TupleSpace
    # TupleFormatError is raised when tuple format is invalid.
    class TupleFormatError < StandardError
      # Creates an error.
      # @param [Array<Object>] invalid_data
      #   invalid data
      # @param [Symbol] identifier
      #   tuple identifier
      def initialize(invalid_data, identifier=nil)
        @invalid_data = invalid_data
        @identifier = identifier
      end

      # Returns a message of this error.
      # @return [String]
      #   message string with invalid data and tuple identifier
      # @api private
      def message
        msg = "Format error found in %s tuple: %s" % [@identifier, @invalid_data.inspect]
        return msg
      end
    end
  end
end
