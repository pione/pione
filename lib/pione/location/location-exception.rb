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
        "location \"%s\" not found" % @location.address
      end
    end

    # InvalidFileOperation represents you do file operation to directory.
    class InvalidFileOperation < LocationError
      def message
        "invalid file operation: %s" % @location.inspect
      end
    end

    # GitError is raised when git command operation fails.
    class GitError < LocationError
      def message
        "%s: %s" % [@option[:message], @location.address]
      end
    end

    # NotLocal is raised when local location is expected but it is other type location.
    class NotLocal < LocationError
      def initialize(location)
        @location = location
      end

      def message
        "the location \"%s\" should local location" % @location.address
      end
    end

    # `DropboxLocationUnavailable` is raised when Dropbox location isn't
    # unavailable.
    class DropboxLocationUnavailable < LocationError
      def initialize(message)
        @message = message
      end

      def message
        @message
      end
    end
  end
end
