module Pione
  module Location
    # LocalLocation represents local disk locations.
    class LocalLocation < BasicLocation
      set_scheme "local"

      def initialize(uri)
        super(uri.absolute)
      end

      def rebuild(path)
        scheme = @uri.scheme
        path = path.expand_path.to_s
        Location["%s:%s" % [scheme, path]]
      end

      def create(data)
        if @path.exist?
          raise ExistAlready.new(self)
        else
          @path.dirname.mkpath unless @path.dirname.exist?
          @path.open("w+"){|f| f.write(data)}
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
        @path.exist? ? @path.read : (raise NotFound.new(self))
      end

      def update(data)
        if @path.exist?
          @path.open("w+"){|file| file.write(data)}
        else
          raise NotFound.new(@uri)
        end
      end

      def delete
        @path.delete if @path.exist?
      end

      def mtime
        @path.exist? ? @path.mtime : (raise NotFound.new(self))
      end

      def entries
        @path.entries.select{|entry| (@path + entry).file?}.map do |entry|
          Location["local:%s" % (@path + entry).expand_path]
        end
      rescue Errno::ENOENT
        raise NotFound.new(self)
      end

      def file?
        @path.file?
      end

      def directory?
        @path.directory?
      end

      def exist?
        @path.exist?
      end

      def move(dest)
        raise NotFound.new(self) unless exist?
        if dest.kind_of?(LocalLocation)
          dest.path.dirname.mkpath unless dest.path.dirname.exist?
          FileUtils.mv(@path, dest.path)
        else
          copy(dest)
          delete
        end
      end

      def copy(dest)
        if dest.kind_of?(LocalLocation)
          dest.path.dirname.mkpath unless dest.path.dirname.exist?
          IO.copy_stream(@path.open, dest.path)
        else
          dest.exist? ? dest.update(read) : dest.create(read)
        end
      end

      def link(orig)
        if orig.kind_of?(LocalLocation)
          @path.make_symlink(orig.path)
        else
          orig.copy(self)
        end
      end

      def turn(dest)
        if dest.kind_of?(LocalLocation)
          move(dest)
          link(dest)
        else
          copy(dest)
        end
      end
    end
  end
end
