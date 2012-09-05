require 'pione/uri'

module Pione
  module Resource
    class ResourceException < Exception
      def initialize(uri)
        @uri = uri
      end
    end

    class NotFound < ResourceException; end

    @@schemes = {}

    def self.[](uri)
      uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
      @@schemes[uri.scheme].new(uri)
    end

    Hint = Struct.new(:domain, :outputs)

    class Base
      def create(data)
        raise NotImplementedError
      end

      def read
        raise NotImplementedError
      end

      def update(data)
        raise NotImplementedError
      end

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

    class Local < Base
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(URI::Local)
        @path = uri.path
      end

      def create(data)
        dir = File.dirname(@path)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        File.open(@path, "w+"){|file| file.write(data)}
      end

      def read
        if File.exist?(@path)
          File.read(@path)
        else
          raise NotFound.new(@uri)
        end
      end

      def update(data)
        if File.exist?(@path)
          File.open(@path, "w+"){|file| file.write(data)}
        else
          raise NotFound.new(@uri)
        end
      end

      def delete
        File.delete(@path)
      end

      def copy_to(dist)
        FileUtil.symlink(@path, dist)
      end

      def copy_from(src)
        swap(src)
      end

      # Swaps the source file and the resource file. This method moves the
      # other file to the resource path and creates a symbolic link from
      # distination to source.
      def swap(other)
        dir = File.dirname(@path)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        FileUtils.mv(other, @path)
        FileUtils.symlink(@path, other)
      end
    end

    @@schemes['local'] = Local

    require 'net/ftp'

    class FTP
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(::URI::FTP)
        @path = uri.path
      end

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

      def delete
        Net::FTP.open(@uri.host, @uri.user, @uri.password) do |ftp|
          ftp.delete(@path)
        end
      end

      def copy_to(dist)
        FileUtil.symlink(@path, dist)
      end

      private

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
