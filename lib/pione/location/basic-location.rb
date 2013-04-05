module Pione
  module Location
    # LocationError is raised when any resource errors happen.
    class LocationError < Exception
      def initialize(uri)
        @uri = uri
      end
    end

    # UnknonwLocation is raised when URI is unknown location for PIONE.
    class Unknown < LocationError; end

    # NotFound is raised when there isn't data on the location.
    class NotFound < LocationError; end

    # known schemes table
    SCHEMES = {}

    # Return the location object corresponding to the URI.
    #
    # @param uri [URI or String]
    #   URI or location representing string
    # @return [BasicLocation]
    #   location object
    def self.[](uri)
      uri = URI.parse(uri.to_s)
      uri = uri.scheme ? uri : URI.parse("local:%s" % Pathname.new(uri.path).expand_path)
      if location_class = SCHEMES[uri.scheme]
        location_class.new(uri)
      else
        raise Unknown.new(uri)
      end
    end

    # BasicLocation is a class for all location classes.
    class BasicLocation
      class << self
        attr_reader :scheme

        # Declare the name as location scheme.
        def set_scheme(name)
          @scheme = name
          SCHEMES[name] = self
        end
      end

      # @return [URI]
      attr_reader :uri

      # @return [Pathname]
      attr_reader :path

      # Create a location with the URI.
      #
      # @param uri [URI]
      #   location URI
      def initialize(uri)
        @uri = uri.kind_of?(URI::Generic) ? uri : URI.parse(uri)
        raise ArgumentError unless @uri.scheme = self.class.scheme
        @path = Pathname.new(uri.path)
      end

      # Create new location appended the name.
      #
      # @param name [String]
      #   filename or directory name
      def +(name)
        self.class.new(@uri.as_directory + name)
      end

      # Creates a location.
      #
      # @param data [String]
      #   data content
      # @return[void]
      def create(data)
        raise NotImplementedError
      end

      # Read location data.
      #
      # @return [String]
      #   data content
      def read
        raise NotImplementedError
      end

      # Update with the data.
      #
      # @param data [String]
      #   new data content
      # @return [void]
      def update(data)
        raise NotImplementedError
      end

      # Delete data of the location.
      #
      # @return [void]
      def delete
        raise NotImplementedError
      end

      # Return last modification time of the location.
      #
      # @return [Time]
      #   last modification time
      def mtime
        raise NotImplementedError
      end

      # Return entries of the resource path.
      #
      # @return [Array<Location>]
      #   entries of the location path
      def entries
        raise NotImplementedError
      end

      # Return the basename of resource.
      #
      # @return [String]
      #   basename
      def basename
        raise NotImplementedError
      end

      # Return true if there is data in the location.
      #
      # @return [Boolean]
      #   if there is data in the location
      def exist?
        raise NotImplementedError
      end

      # Link to the destination.
      #
      # @param dest [Pathname]
      #   destination path
      # @return [void]
      def link_to(dest)
        raise NotImplementedError
      end

      # Link form the source.
      #
      # @param src [Pathname]
      #   source path
      # @return [void]
      def link_from(src)
        raise NotImplementedError
      end
    end
  end
end
