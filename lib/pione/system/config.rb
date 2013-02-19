module Pione
  module System
    # Config is a class for setting PIONE system configuration.
    class Config < PioneObject
      extend Forwardable

      # This exception class is raised when configuration file is in invalid format.
      class InvalidConfigFormat < StandardError
        # config file path
        # @return [Pathname]
        attr_reader :path

        # Create an exception.
        #
        # @param path [Pathname]
        #   configuration file path
        def initialize(path)
          @path = path
        end

        # @api private
        def message
          "invalid format configuration file: %s" % @path
        end
      end

      class << self
        # Load configuration and apply it to global settings.
        #
        # @param path [Pathname or String]
        #   configuration file path
        # @return [void]
        def load(path)
          new(path).tap {|x| x.apply}
        end
      end

      def_delegator :@table, "[]"

      # config file path
      # @return [Pathname]
      attr_reader :path

      # Create a new configuration.
      #
      # @param path [Pathname or String]
      #   configuration file path
      def initialize(path)
        @path = Pathname.new(path)
        @table = @path.exist? ? YAML.load(@path.read) : {}
        raise InvalidConfigFormat.new(@path) unless @table.kind_of?(Hash)
      end

      # Apply config date to global settings.
      #
      # @return [void]
      def apply
        # set values
        keys = Global.all_names
        @table.each do |key, val|
          Global.send("set_%s" % key, val) if keys.include?(key.to_sym)
        end
        # initialize global settings with new configuration
        Global.init
      end
    end
  end
end
