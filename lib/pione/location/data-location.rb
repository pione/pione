module Pione
  module Location
    class DataLocation < BasicLocation
      location_type :data

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

        def set_real_appendable(b)
          @appendable = b
        end

        def real_appendable?
          @appendable
        end

        def set_writable(b)
          @writable = b
        end

        def writable?
          @writable
        end
      end

      forward! :class, :scheme, :real_appendable?, :writable?
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
        @address = uri.to_s
        @uri = uri.kind_of?(URI::Generic) ? uri : URI.parse(uri)
        @path = Pathname.new(uri.path)
        raise ArgumentError.new(uri) unless @uri.scheme = scheme
      end

      # Copy the content to temporary local location and return the location. If
      # the scheme is local, return itself.
      def local
        if scheme == "local"
          self
        else
          Location[Temppath.create].tap {|tmp| copy(tmp) if exist?}
        end
      end

      # Return true if scheme of the location is local.
      def local?
        scheme == "local"
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

      # Return the extension name of location.
      #
      # @return
      #    the extension name of location
      def extname
        File.extname(basename)
      end

      # Return the dirname of location. This method returns it as a location.
      def dirname
        rebuild(@path.dirname).as_directory
      end

      # Rebuild location with the path.
      #
      # @param path [Pathname]
      #   new path
      # @return [Location]
      #   location with new path
      def rebuild(path)
        scheme = @uri.scheme
        auth = @uri.user and @uri.password ? "%s:%s@" % [@uri.user, @uri.password] : ""
        host = @uri.host
        port = @uri.port ? ":%i" % @uri.port : ""
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

      # Write a data into the location.
      #
      # @param data [String]
      #   data content
      # @return [void]
      def write(data)
        if exist?
          update(data)
        else
          create(data)
        end
      end

      # Creates a file at the location. If a file exists at the location aleady,
      # it raises an exception.
      #
      # @param data [String]
      #   data content
      # @return [void]
      def create(data)
        raise NotImplementedError
      end

      # Append data to the location data.
      #
      # @param data [String]
      #   data content
      # @return [void]
      def append(data)
        if @real_appendable
          raise NotImplmentedError
        else
          _local = local
          _local.append(data)
          _local.copy(self)
        end
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

      # Return ctime of the location.
      #
      # @return [Time]
      #   ctime
      def ctime
        raise NotImplementedError
      end

      # Return mtime of the location.
      #
      # @return [Time]
      #   mtime
      def mtime
        raise NotImplementedError
      end

      # Set mtime of the location.
      #
      # @return [void]
      def mtime=(time)
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
      def entries(&b)
        raise NotImplementedError
      end

      # Return relative entries of the location.
      #
      # @return [Array<String>]
      #   entries of the location
      def rel_entries(option)
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

      # Return true if data at the location is a file. When there exists no
      # files and no directories, then return false.
      #
      # @return [Boolean]
      #   true if data at the location is a file
      def file?
        raise NotImplementedError
      end

      # Return true if data at the location is a directory. When there exists no
      # files and no direcotries, then return false.
      #
      # @return [Boolean]
      #   true if data at the location is a directory
      def directory?
        raise NotImplementedError
      end

      # Make the path a directory.
      #
      # @return [void]
      def mkdir
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

      # Return the digest string by SHA1.
      #
      # @return [String]
      #   hex-string of the file
      def sha1
        if file?
          Digest::SHA1.file(local.path)
        else
          raise InvalidFileOperation.new(self)
        end
      end

      # @api private
      def inspect
        "#<%s %s:%s>" % [self.class, scheme, @path.to_s]
      end
      alias :to_s :inspect

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

