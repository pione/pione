module Pione
  module Location
    # FTPLocation represents locations on FTP server.
    class FTPLocation < DataLocation
      set_scheme "ftp"
      set_real_appendable false

      # for myftp scheme
      SCHEMES["myftp"] = self

      def initialize(uri)
        uri = uri.to_ftp_scheme if uri.scheme == "myftp"
        super(uri)
      end

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
            path = Temppath.create
            Location[path].create(data)
            ftp.put(path, @path.to_s)
          end
        end
      end

      def append(data)
        if exist?
          update(read + data)
        else
          create(data)
        end
      end

      def read
        file = Temppath.create
        connect {|ftp| ftp.get(@path, file.to_s)}
        return File.read(file.to_s)
      rescue Net::FTPPermError
        raise NotFound.new(@uri)
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

      def mkdir
        connect {|ftp| makedirs(ftp, @path)} unless exist?
      end

      def mtime
        connect {|ftp| exist? ? ftp.mtime(@path.to_s) : (raise NotFound.new(self))}
      end

      def size
        connect {|ftp| exist? ? ftp.size(@path.to_s) : (raise NotFound.new(self))}
      end

      def entries(option={})
        rel_entries(option).map {|entry| rebuild(@path + entry)}
      end

      def rel_entries(option={})
        list = []
        connect do |ftp|
          ftp.nlst(@path.to_s).each do |entry|
            list << entry
            entry_location = rebuild(@path + entry)
            if option[:rec] and entry_location.directory?
              _list = entry_location.rel_entries(option).map {|subentry| entry + subentry}
              list = list + _list
            end
          end
        end
        return list
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
          connect{|ftp| ftp.rename(@path.to_s, dest.path.to_s)}
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
