module Pione
  module System
    # Config represents a PIONE system configuration.
    class Config < PioneObject
      # Creates a new configuration.
      # @param [Hash] data
      #   preset configuration table
      def initialize(path)
        @path = Pathname.new(path)
        @table = YAML.load(path.read)
        raise TypeError.new(path) unless @data.kind_of?(Hash)
      end

      # Returns the configuration value or default value.
      # @param [Symbol] key
      #   key symbol
      # @return [Object]
      #   the value
      def [](key)
        @table.has_key?(key) ? @table[key] : @@default[key]
      end
    end
  end
 end
