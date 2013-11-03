module Pione
  module Package
    class PackageError < StandardError; end

    # NotFound is raised when package not found in package database.
    class NotFound < PackageError
      def initialize(name, editor, tag)
        @name = name
        @editor = eidition
        @tag = tag
      end

      def message
        "the package(name: %s, editor: %s, tag: %s) not found" % [@name, @editor, @tag]
      end
    end

    # InvalidPackageFilename is raised when parser fails to parse package filename.
    class InvalidPackageFilename < PackageError
      def initialize(name, error)
        @name = name   # package filename
        @error = error # parser exception
      end

      def message
        "invalid package filename \"%s\": %s" % [@name, @error.message]
      end
    end

    # InvalidPackage raises when the package is something bad.
    class InvalidPackage < PackageError; end

    # InvalidScenario raises when the package is something bad.
    class InvalidScenario < PackageError
      def initialize(location, reason)
        @location = location
        @reason = reason
      end

      def message
        "%<path>s is an invalid scenario document: %<reason>s" % args
      end

      def args
        {
          :path => @location.path,
          :reason => @reason
        }
      end
    end

    class DatabaseError < PackageError; end
  end
end
