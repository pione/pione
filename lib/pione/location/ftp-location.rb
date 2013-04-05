module Pione
  module Location
    # FTPLocation represents locations on FTP server.
    class FTPLocation < BasicLocation
      set_scheme "ftp"

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

      def link_to(dist)
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
  end
end
