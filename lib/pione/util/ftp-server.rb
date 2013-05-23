module Pione
  module Util
    # FTPAuthInfo is a class for FTP authentication information.
    class FTPAuthInfo
      attr_reader :user
      attr_reader :password

      def initialize(user=nil, password=nil)
        @user = user || Util::UUID.generate[0...12]
        @password = password || Util::UUID.generate[0...12]
      end

      def to_userinfo
        "%s:%s" % [@user, @password]
      end
    end

    class FTPFileSystem
      # Return true if the path is a directory or a file.
      #
      # @param path [Pathname]
      #   the path
      # @return [Boolean]
      #   true if the path is a directory or a file
      def exist?(path)
        directory?(path) or file?(path)
      end

      # Return true if the path is a directory.
      #
      # @param path [Pathname]
      #   the path
      # @return [Boolean]
      #   true if the path is a directory
      def directory?(path)
        raise NotImplemented
      end

      # Return true if the path is a file.
      #
      # @param path [Pathname]
      #   the path
      # @return [Boolean]
      #   true if the path is a file
      def file?(path)
        raise NotImplemented
      end

      # Return content of the file.
      #
      # @param path [Pathname]
      #   the path
      # @return [String]
      #   file content
      def get_file(path)
        raise NotImplemented
      end

      # Put the data into the path and return the byte size.
      #
      # @param path [Pathname]
      #   the path
      # @param data [Pathname]
      #   data file path
      # @return [Integer]
      #   byte size of the data
      def put_file(path, data)
        raise NotImplemented
      end

      # Delete the file.
      #
      # @param path [Pathname]
      #   the path
      # @return [void]
      def delete_file(path)
        raise NotImplemented
      end

      # Return byte size of the path.
      #
      # @param path [Pathname]
      #   the path
      # @return [Integer]
      #   byte size
      def get_size(path)
        raise NotImplemented
      end

      # Return mtime of the path. If the path doesn't exist, return nil.
      #
      # @param path [Pathname]
      #   the path
      # @return [Time]
      #   mtime
      def get_mtime(path)
        raise NotImplemented
      end

      # Return entries of the directory.
      #
      # @param path [Pathname]
      #   the path
      # @return [Pathname]
      #   entry names
      def entries(path)
        raise NotImplemented
      end

      # Make a directory at the path.
      #
      # @param path [Pathname]
      #   the path
      # @return [void]
      def mkdir(path)
        raise NotImplemented
      end

      # Delete a directory at the path.
      #
      # @param path [Pathname]
      #   the path
      # @return [void]
      def rmdir(path)
        raise NotImplemented
      end

      # Move file.
      #
      # @param from_path [Pathname]
      #    from path
      # @param to_path [Pathname]
      #    to path
      # @return [void]
      def mv(from_path, to_path)
        raise NotImplemented
      end
    end

    # OnMemoryFS is a virtual file system on memory.
    class FTPOnMemoryFS < FTPFileSystem
      ROOT = Pathname.new("/")

      attr_reader :directory
      attr_reader :file
      attr_reader :mtime

      def initialize
        @directory = {ROOT => Set.new}
        @file = {}
        @mtime = {}
      end

      # Clear file system items.
      #
      # @return [void]
      def clear
        @directory.clear
        @directory[ROOT] = Set.new
        @file.clear
        @mtime.clear
      end

      def directory?(path)
        @directory.has_key?(path)
      end

      def file?(path)
        @file.has_key?(path)
      end

      def get_file(path)
        @file[path]
      end

      def put_file(path, data)
        @directory[path.dirname] << path.basename
        @file[path] = File.read(data)
        @mtime[path] = Time.now
      end

      def delete_file(path)
        @directory[path.dirname].delete(path.basename)
        @file.delete(path)
        @mtime.delete(path)
      end

      def get_size(path)
        @file[path].bytesize
      end

      def get_mtime(path)
        @mtime[path]
      end

      def entries(path)
        @directory[path]
      end

      def mkdir(path)
        @directory[path] = Set.new
        unless path == path.dirname
          @directory[path.dirname] << path.basename
        end
      end

      def rmdir(path)
        @directory.delete(path)
        unless path == path.dirname
          @directory[path.dirname].delete(path.basename)
        end
      end

      def mv(from_path, to_path)
        @directory[to_path.dirname] << from_path.basename
        @directory[from_path.dirname].delete(from_path.basename)
        @file[to_path] = @file[from_path]
        @file.delete(from_path)
        @mtime[to_path] = @file[from_path]
        @mtime.delete(to_path)
      end
    end

    class FTPLocalFS < FTPFileSystem
      attr_reader :directory
      attr_reader :file
      attr_reader :mtime

      def initialize(base)
        @base = base
      end

      def directory?(path)
        merge(path).directory?
      end

      def file?(path)
        merge(path).file?
      end

      def get_file(path)
        merge(path).read
      end

      def put_file(path, data)
        Location[data].copy(merge(path))
      end

      def delete_file(path)
        merge(path).delete
      end

      def get_size(path)
        merge(path).size
      end

      def get_mtime(path)
        merge(path).mtime
      end

      def entries(path)
        merge(path).entries.map{|entry| Pathname.new(entry.basename)}
      end

      def mkdir(path)
        merge(path).path.mkdir
      end

      def rmdir(path)
        merge(path).path.rmdir
      end

      def mv(from_path, to_path)
        merge(from_path).path.rename(merge(to_path).path)
      end

      private

      def merge(path)
        @base + path.relative_path_from(Pathname.new("/"))
      end
    end

    class FTPServer
      @auth_info = FTPAuthInfo.new
      @port = 39123

      class << self
        attr_accessor :auth_info
        attr_accessor :fs
        attr_accessor :port
        attr_reader :thread

        # Start FTP server.
        def start(fs)
          @fs = fs
          @thread = Thread.new do
            EventMachine.run do
              EventMachine.start_server("0.0.0.0", @port, EM::FTPD::Server, self)
            end
          end
        end

        def stop
          if EventMachine.reactor_running?
            EventMachine.stop
          end
          @thread.kill if @thread
        end

        def make_location(path)
          Location["ftp://%s:%s@localhost:%i%s" % [@auth_info.user, @auth_info.password, @port, path]]
        end
      end

      forward! :class, :auth_info, :fs, :port

      # Change directory.
      def change_dir(path, &b)
        path = Pathname.new(path).cleanpath
        yield fs.directory?(path)
      end

      # Return entries of the directory.
      def dir_contents(path, &b)
        path = Pathname.new(path).cleanpath
        if fs.directory?(path)
          entries = fs.entries(path).map do |entry|
            entry_path = path + entry
            if fs.directory?(entry_path)
              dir_item(entry)
            else
              file_item(entry, fs.get_size(entry_path))
            end
          end
          yield entries
        else
          yield Set.new
        end
      end

      # Authenticate the user.
      def authenticate(user, password, &b)
        yield auth_info.user == user && auth_info.password == password
      end

      # Get byte size of the path.
      def bytes(path, &b)
        path = Pathname.new(path).cleanpath
        if fs.file?(path)
          yield fs.get_size(path)
        elsif fs.directory?(path)
          yield -1
        else
          yield false
        end
      end

      # Get file content of the path.
      def get_file(path, &block)
        path = Pathname.new(path).cleanpath
        if fs.file?(path)
          yield fs.get_file(path)
        else
          yield false
        end
      end

      # Put data to the path.
      def put_file(path, data, &b)
        path = Pathname.new(path).cleanpath
        dir = path.dirname
        filename = path.basename
        if fs.directory?(dir) and filename
          fs.put_file(path, data)
          yield data.size
        else
          yield false
        end
      end

      # Delete file of the path.
      def delete_file(path, &b)
        path = Pathname.new(path).cleanpath
        dir = path.dirname
        filename = path.basename
        if fs.directory?(dir) and fs.entries(dir).include?(filename)
          fs.delete_file(path)
          yield true
        else
          yield false
        end
      end

      # Rename the file.
      def rename_file(from, to, &b)
        from_path = Pathname.new(from).cleanpath
        from_dir = from_path.dirname
        from_filename = from_path.basename
        to_path = Pathname.new(to).cleanpath
        to_dir = to_path.dirname
        to_filename = to_path.basename
        if fs.file?(from_path) && fs.directory?(to_dir)
          data = fs.get_file(from_path)
          fs.delete_file(from_path)
          fs.put_file(to_path, data)
          yield true
        else
          yield false
        end
      end

      # Make the directory.
      def make_dir(path, &b)
        path = Pathname.new(path).cleanpath
        dir = path.dirname
        if fs.exist?(path) or not(fs.directory?(dir))
          yield false
        else
          fs.mkdir(path)
          yield true
        end
      end

      # Delete the directory.
      def delete_dir(path, &b)
        path = Pathname.new(path).cleanpath
        if fs.directory?(path) and fs.entries(path).empty?
          fs.rmdir(path)
          yield true
        else
          yield false
        end
      end

      # Return the mtime.
      def mtime(path)
        path = Pathname.new(path).cleanpath
        if mtime = fs.get_mtime(path)
          yield mtime
        else
          yield false
        end
      end

      def rename(from_path, to_path, &b)
        from_path = Pathname.new(from_path).cleanpath
        to_path = Pathname.new(to_path).cleanpath
        if fs.file?(from_path) and fs.directory?(to_path.dirname)
          fs.mv(from_path, to_path)
          yield true
        else
          yield false
        end
      end

      private

      def dir_item(name)
        EM::FTPD::DirectoryItem.new(:name => name, :directory => true, :size => 0)
      end

      def file_item(name, bytes)
        EM::FTPD::DirectoryItem.new(:name => name, :directory => false, :size => bytes)
      end
    end
  end
end
