module Pione
  # Resource is a module for data resources.
  module Resource
    # ResourceError is raised when any resource errors happen.
    class ResourceError < Exception
      def initialize(uri)
        @uri = uri
      end
    end

    class NotFound < ResourceError; end

    # @api private
    @@schemes = {}

    # Returns the resource object corresponding to the uri.
    # @return [BasicResource]
    #   resouce object
    def self.[](uri)
      uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
      @@schemes[uri.scheme].new(uri)
    end

    # BasicResource is an interface class for all resouce classes.
    class BasicResource
      attr_reader :uri
      attr_reader :path

      # Creates a data resource on URI.
      # @param [String] data
      #   data content
      # @return[void]
      def create(data)
        raise NotImplementedError
      end

      # Reads a resource data from URI.
      # @return [String]
      #   data content
      def read
        raise NotImplementedError
      end

      # Updates a resource data on URI.
      # @param [String] data
      #   new data content
      # @return [void]
      def update(data)
        raise NotImplementedError
      end

      # Deletes a resource data on URI.
      # @return [void]
      def delete
        raise NotImplementedError
      end

      # Returns mtime of the resource.
      # @return [Time]
      #   mtime
      def mtime
        raise NotImplementedError
      end

      # Returns entries of the resource path.
      # @return [Array<Resource>]
      #   resource entries of the resource path
      def entries
        raise NotImplementedError
      end

      # Returns the basename of resource.
      # @return [String]
      #   basename
      def basename
        raise NotImplementedError
      end

      def exist?
        raise NotImplementedError
      end

      def link_to(dist)
        raise NotImplementedError
      end

      def link_from(dist)
        raise NotImplementedError
      end
    end
  end
end
