module Pione
  module Location
    # FTPLocation represents locations on FTP server.
    class FTPLocation < BasicLocation
      set_scheme "ftp"

      def rebuild(path)
        scheme = @uri.scheme
        auth = "%s:%s@" % [@uri.user, @uri.password] if @uri.user and @uri.password
        host = @uri.host
        port = ":%i" % @uri.port
        path = Pathname.new(path).expand_path("/").to_s
        Location["%s://%s%s%s%s" % [scheme, auth, host, port, path]]
      end

      def create(data)
        if exist?
          raise ExistAlready.new(self)
        else
          connect do |ftp|
            makedirs(ftp, @path.dirname)
            file = Temppath.create
            file.open("w") {|f| f.write(data)}
            ftp.put(file.to_s, @path.to_s)
          end
        end
      end

      def append(data)
        exist? ? update(read + data) : create(data)
      end

      def read
        begin
          data = nil
          file = Temppath.create
          connect {|ftp| ftp.get(@path, file.to_s)}
          data = File.read(file.to_s)
          return data
        rescue Net::FTPPermError
          raise NotFound.new(@uri)
        end
      end

      def update(data)
        connect do |ftp|
          begin
            ftp.dir(@path.dirname.to_s)
            src = Temppath.create.tap{|x| x.open("w") {|f| f.write(data)}}.to_s
            ftp.put(src, @path.to_s)
          rescue Net::FTPPermError
            raise NotFound.new(@uri)
          end
        end
      end

      def delete
        connect {|ftp| ftp.delete(@path.to_s)} if exist?
      end

      def mtime
        connect {|ftp| exist? ? ftp.mtime(@path.to_s) : (raise NotFound.new(self))}
      end

      def size
        connect {|ftp| exist? ? ftp.size(@path.to_s) : (raise NotFound.new(self))}
      end

      def entries
        connect do |ftp|
          ftp.nlst(@path.to_s).map do |entry|
            rebuild(@path + entry)
          end.select {|entry| entry.file?}
        end
      end

      def exist?
        file? or directory?
      end

      def file?
        begin
          connect {|ftp| ftp.size(@path.to_s) > -1}
        rescue
          false
        end
      end

      def directory?
        connect do |ftp|
          begin
            ftp.chdir(@path.to_s)
            return true
          rescue
            return false
          end
        end
      end

      def copy(dest)
        dest.create(read)
      end

      def link(orig)
        orig.copy(self)
      end

      def move(dest)
        if dest.scheme == scheme and dest.host == host
          ftp.rename(@path.to_s, dest.path.to_s)
        else
          copy(dest)
          delete
        end
      end

      def turn(dest)
        copy(dest)
      end

      def inspect
        scheme = @uri.scheme
        auth = "%s:%s@" % [@uri.user, @uri.password] if @uri.user and @uri.password
        host = @uri.host
        port = ":%i" % @uri.port
        path = @path.expand_path("/").to_s
        "#<%s %s://%s%s%s%s>" % [self.class, scheme, auth, host, port, path]
      end

      private

      # Connect to FTP server with the block.
      def connect(&b)
        3.times do
          begin
            ftp = Net::FTP.new
            ftp.connect(@uri.host, @uri.port)
            ftp.passive = true
            ftp.login(@uri.user, @uri.password) if @uri.user
            return yield ftp
          rescue Errno::ECONNREFUSED
            sleep 1
          end
        end
        raise
      end

      # @api private
      def makedirs(ftp, path, size=0)
        path.descend do |dpath|
          ftp.mkdir(dpath.to_s) unless rebuild(dpath).exist?
        end
      end
    end
  end
end
