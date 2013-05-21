module Pione
  module Location
    # LocationError is raised when any resource errors happen.
    class LocationError < Exception
      def initialize(location)
        @location = location
      end
    end

    # ExistAlready is raised when there is data on the location already.
    class ExistAlready < LocationError; end

    # NotFound is raised when there isn't data on the location.
    class NotFound < LocationError
      def message
        "%s not found" % @location.inspect
      end
    end

    # known schemes table
    SCHEMES = {}

    # Return the location object corresponding to the URI.
    #
    # @param uri [URI,String]
    #   URI or location representing string
    # @return [BasicLocation]
    #   location object
    def self.[](uri)
      uri = URI.parse(uri.to_s)
      uri = uri.scheme ? uri : URI.parse("local:%s" % Pathname.new(uri.path).expand_path)
      if location_class = SCHEMES[uri.scheme]
        location_class.new(uri)
      else
        raise ArgumentError.new(uri)
      end
    end

    # BasicLocation is a class for all location classes.
    class BasicLocation
      class << self
        # @return [String]
        #   location's scheme name
        attr_reader :scheme

        # Declare the name as location scheme.
        #
        # @param name [String]
        #   scheme name
        def set_scheme(name)
          @scheme = name
          SCHEMES[name] = self
        end
      end

      forward :class, :scheme
      forward :@uri, :host

      # @return [URI]
      #   URI of the location
      attr_reader :uri

      # @return [Pathname]
      #   path of the location
      attr_reader :path

      # Create a location with the URI.
      #
      # @param uri [URI]
      #   location URI
      def initialize(uri)
        @uri = uri.kind_of?(URI::Generic) ? uri : URI.parse(uri)
        @path = Pathname.new(uri.path)
        raise ArgumentError.new(uri) unless @uri.scheme = scheme
      end

      # Create new location appended the name.
      #
      # @param name [String]
      #   filename or directory name
      # @return [BasicLocation]
      #   new location
      def +(name)
        self.class.new(@uri.as_directory + name.to_s)
      end

      # Create new location that has URI as a directory.
      #
      # @return [BasicLocation]
      #   new location
      def as_directory
        self.class.new(@uri.as_directory)
      end

      # Return the basename of the location.
      #
      # @param suffix [String]
      #   suffix name
      # @return [String]
      #   basename
      def basename(suffix="")
        File.basename(@path, suffix)
      end

      # Rebuild location with the path.
      #
      # @param path [Pathname]
      #   new path
      # @return [Location]
      #   location with new path
      def rebuild(path)
        scheme = @uri.scheme
        auth = "%s:%s@" % [@uri.user, @uri.password] if @uri.user and @uri.password
        host = @uri.host
        port = ":%i" % @uri.port
        path = path.expand_path("/").to_s
        Location["%s://%s%s%s%s" % [scheme, auth, host, port, path]]
      end

      # Return true if the location is cached.
      #
      # @return [Boolean]
      #   true if the location is cached
      def cached?
        System::FileCache.cached?(self)
      end

      # Creates a location.
      #
      # @param data [String]
      #   data content
      # @return[void]
      def create(data)
        raise NotImplementedError
      end

      # Append data to the location data.
      #
      # @param data [String]
      #   data content
      # @return [void]
      def append(data)
        raise NotImplmentedError
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

      # Return byte size of data in the location.
      #
      # @return [Integer]
      #   byte size of data
      def size
        raise NotImplementedError
      end

      # Return entries of the location.
      #
      # @return [Array<Location>]
      #   entries of the location
      def entries
        raise NotImplementedError
      end

      # Return file entries of the location.
      #
      # @return [Array<Location>]
      #    file entries of the location
      def file_entries
        entries.select{|entry| entry.file?}
      end

      # Return directory entries of the location.
      #
      # @return [Array<Location>]
      #    directory entries of the location
      def directory_entries
        entries.select do |entry|
          entry.directory? and not(entry.path.basename == "." or entry.path.basename == "..")
        end
      end

      # Return true if there is data in the location.
      #
      # @return [Boolean]
      #   if there is data in the location
      def exist?
        raise NotImplementedError
      end

      # Return true if data in the location is a file.
      #
      # @return [Boolean]
      #   true if data in the location is a file
      def file?
        raise NotImplementedError
      end

      # Return true if data in the location is a directory.
      #
      # @return [Boolean]
      #   true if data in the location is a directory
      def directory?
        raise NotImplementedError
      end

      # Move to the destination.
      #
      # @param dest [BasicLocation]
      #   destination
      # @return [void]
      def move(dest)
        raise NotImplementedError
      end

      # Copy location's content to the destination.
      #
      # @param dest [BasicLocation]
      #   destination
      # @return [void]
      def copy(dest)
        raise NotImplementedError
      end

      # Link to the destination. If the location scheme is same to destination,
      # create link by a symbolic link or lightweight copy method. If not, copy
      # it simply.
      #
      # @param dest [BasicLocation]
      #   destination
      # @return [void]
      def link(dest)
        raise NotImplementedError
      end

      # Move data to the destination and link self to it.
      #
      # @param dest [BasicLocation]
      #   destination
      # @return [void]
      def turn(dest)
        raise NotImplementedError
      end

      # @api private
      def inspect
        "#<%s %s:%s>" % [self.class, scheme, @path.to_s]
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @uri == other.uri
      end
      alias :eql? :"=="

      # @api private
      def hash
        @uri.hash
      end
    end
  end
end
