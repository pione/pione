module Pione
  module System
    class SystemException < StandardError; end

    # This exception class is raised when configuration file is in invalid format.
    class InvalidConfigFile < SystemException
      # config file path
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def message
        "invalid format configuration file: %s" % @path
      end
    end

    class UnconfigurableVariableError < SystemException
      def initialize(name)
        @name = name
      end

      def message
        "global variable \"%s\" is unconfigurable." % @name
      end
    end
  end
end
