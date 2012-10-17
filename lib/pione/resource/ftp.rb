module Pione
  module Resource
    # FTP represents resources on FTP server.
    class FTP < BasicResource
      # Creates a resouce.
      # @param [String, ::URI] uri
      #   resource URI
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(::URI::FTP)
        @path = uri.path
      end

      # (see BasicResource#create)
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

      # (see BasicResource#read)
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

      # (see BasicResource#update)
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

      # (see BasicResource#delete)
      def delete
        Net::FTP.open(@uri.host, @uri.user, @uri.password) do |ftp|
          ftp.delete(@path)
        end
      end

      # (see BasicResource#copy_to)
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
