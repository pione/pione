module Pione
  module Global
    class GlobalError < StandardError; end

    # UnknownItem is raised when unknown global item is referred.
    class UnknownItem < GlobalError
      def initialize(name)
        @name = name
      end

      def message
        "item '%s' is unknown as global variables" % @name
      end
    end

    # This exception class is raised when configuration file is in invalid format.
    class InvalidConfigFile < GlobalError
      # config file path
      attr_reader :path

      def initialize(path)
        @path = path
      end

      def message
        "invalid format configuration file: %s" % @path
      end
    end

    class UnconfigurableVariableError < GlobalError
      def initialize(name)
        @name = name
      end

      def message
        "global variable \"%s\" is unconfigurable." % @name
      end
    end
  end
end
