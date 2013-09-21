module Pione
  module Location
    # LocationError is raised when any resource errors happen.
    class LocationError < StandardError
      def initialize(location, option={})
        @location = location
        @option = option
      end
    end

    # ExistAlready is raised when there is data on the location already.
    class ExistAlready < LocationError
      def message
        "the location exists already: %s" % @location.inspect
      end
    end

    # NotFound is raised when there isn't data on the location.
    class NotFound < LocationError
      def message
        "%s not found" % @location.inspect
      end
    end

    # InvalidFileOperation represents you do file operation to directory.
    class InvalidFileOperation < LocationError
      def message
        "invalid file operation: %s" % @location.inspect
      end
    end

    class GitError < LocationError
      def message
        "%s: %s" % [@option[:message], @location.address]
      end
    end
  end
end
