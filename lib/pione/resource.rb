module Pione
  # Resource is a module for data resources.
  module Resource
    # ResourceException is raised when any resource errors happen.
    class ResourceException < Exception
      def initialize(uri)
        @uri = uri
      end
    end

    class NotFound < ResourceException; end

    # @api private
    @@schemes = {}

    # Returns the resource object corresponding to the uri.
    # @return [Base]
    #   resouce object
    def self.[](uri)
      uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
      @@schemes[uri.scheme].new(uri)
    end

    # FIXME
    # @api private
    Hint = Struct.new(:domain, :outputs)

    # Base is an interface class for all resouce classes.
    class Base
      attr_reader :path

      # Creates a data resource on URI.
      # @param [String] data
      #   data content
      # @return[void]
      def create(data)
        raise NotImplementedError
      end

      # Reads a data resource from URI.
      # @return [String]
      #   data content
      def read
        raise NotImplementedError
      end

      # Updates a data resouce on URI.
      # @param [String] data
      #   new data content
      # @return [void]
      def update(data)
        raise NotImplementedError
      end

      # Deletes a data resource on URI.
      # @return [void]
      def delete
        raise NotImplementedError
      end

      def copy_to(dist)
        raise NotImplementedError
      end

      def copy_from(dist)
        raise NotImplementedError
      end
    end

    # Local represents local path resources.
    class Local < Base
      # Creates a resource path with URI.
      # @param [String, URI] uri
      #   local path URI
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(URI::Local)
        @path = uri.path
      end

      # (see Base#create)
      def create(data)
        dir = File.dirname(@path)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        File.open(@path, "w+"){|file| file.write(data)}
      end

      # (see Base#read)
      def read
        if File.exist?(@path)
          File.read(@path)
        else
          raise NotFound.new(@uri)
        end
      end

      # (see Base#update)
      def update(data)
        if File.exist?(@path)
          File.open(@path, "w+"){|file| file.write(data)}
        else
          raise NotFound.new(@uri)
        end
      end

      # (see Base#delete)
      def delete
        File.delete(@path)
      end

      # Makes symbolic link from the resource to the destination.
      # @param [String] dest
      #   destination path
      # @return [void]
      def link_to(dest)
        dir = File.dirname(dest)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        FileUtils.symlink(@path, dest)
      end

      # Moves the source to the resource and makes reverse link.
      # @param [String] src
      #   source path
      # @return [void]
      def link_from(src)
        swap(src)
      end

      # Swaps the source file and the resource file. This method moves the
      # other file to the resource path and creates a symbolic link from
      # distination to source.
      # @param [String] other
      #   swap target
      # @return [void]
      def swap(other)
        unless File.ftype(other) == "file"
          raise ArgumentError.new(other)
        end
        dir = File.dirname(@path)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        FileUtils.mv(other, @path)
        FileUtils.symlink(@path, other)
      end

      # Swaps the resouce file and the other resouce file.
      # @param [Local] other
      #   swap target
      def shift_from(other)
        raise ArgumentError.new(other) unless other.kind_of?(self.class)
        unless File.ftype(other.path) == "file"
          raise ArgumentError.new(other)
        end
        dir = File.dirname(@path)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        FileUtils.mv(other.path, @path)
      end
    end

    @@schemes['local'] = Local

    require 'net/ftp'

    # FTP represents resources on FTP server.
    class FTP
      # Creates a resouce.
      # @param [String, ::URI] uri
      #   resource URI
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(::URI::FTP)
        @path = uri.path
      end

      # (see Base#create)
      def create(data)
        Net::FTP.open(@uri.host, @uri.user, @uri.password) do |ftp|
          pathes = @path.split('/')
          makedirs(ftp, pathes)
          t = Tempfile.open("aaa")
          t.write(data)
          t.close(false)
          ftp.put(t.path, @path)
        end
      end

      # (see Base#read)
      def read
        begin
          tempfile = Tempfile.new("test")
          Net::FTP.open(@uri.host, @uri.user, @uri.password) do |ftp|
            ftp.get(@path, tempfile.path)
          end
          File.read(tempfile.path)
        rescue Net::FTPPermErrro
          raise NotFound.new(@uri)
        end
      end

      # (see Base#update)
      def update(data)
        Net::FTP.open(@uri.host, @uri.user, @uri.password) do |ftp|
          begin
            ftp.dir(File.dirname(@path))
            t = Tempfile.open("aaa")
            t.write(data)
            t.close(false)
            ftp.put(t.path, @path)
          rescue Net::FTPPermErrro
            raise NotFound.new(@uri)
          end
        end
      end

      # (see Base#delete)
      def delete
        Net::FTP.open(@uri.host, @uri.user, @uri.password) do |ftp|
          ftp.delete(@path)
        end
      end

      # (see Base#copy_to)
      def copy_to(dist)
        FileUtil.symlink(@path, dist)
      end

      private

      # @api private
      def makedirs(ftp, path, size=0)
        unless path.size == size + 1
          pa = File.join(*path[0..size])
          begin
            ftp.mkdir(pa)
          rescue Net::FTPPermError
          ensure
            makedirs(ftp, path, size+1)
          end
        end
      end
    end

    @@schemes['ftp'] = FTP
  end
end
