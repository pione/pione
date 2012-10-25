module Pione
  module System
    # Config represents a PIONE system configuration.
    class Config < PioneObject
      extend Forwardable

      attr_reader :path
      def_delegator :@table, "[]"

      # Creates a new configuration.
      # @param [Hash] data
      #   preset configuration table
      def initialize(path)
        @path = Pathname.new(path)
        @table = @path.exist? ? YAML.load(@path.read) : {}
        raise TypeError.new(@path) unless @table.kind_of?(Hash)
      end
    end
  end
end
