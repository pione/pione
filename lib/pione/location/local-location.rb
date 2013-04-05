module Pione
  module Location
    # LocalLocation represents local disk locations.
    class LocalLocation < BasicLocation
      set_scheme "local"

      def create(data)
        @path.dirname.mkpath unless @path.dirname.exist?
        @path.open("w+"){|file| file.write(data)}
      end

      def read
        @path.exist? ? @path.read : (raise NotFound.new(@uri))
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
        @path.mtime
      end

      def entries
        @path.entries.select{|entry| (@path + entry).file?}.map do |entry|
          Location[URI.parse("local:%s" % (@path + entry).expand_path)]
        end
      rescue Errno::ENOENT
        raise NotFound.new(self)
      end

      def basename
        @path.basename.to_s
      end

      def exist?
        @path.exist?
      end

      def link_to(dest)
        dir = File.dirname(dest)
        FileUtils.makedirs(dir) unless Dir.exist?(dir)
        FileUtils.symlink(@path, dest)
      end

      def link_from(src)
        swap(src)
      end

      # Swaps the source file and the resource file. This method moves the
      # other file to the resource path and creates a symbolic link from
      # distination to source.
      #
      # @param [String] other
      #   swap target
      # @return [void]
      def swap(other)
        unless File.ftype(other) == "file"
          raise ArgumentError.new(other)
        end
        dir = @path.dirname
        dir.mkpath unless dir.exist?
        FileUtils.mv(other, @path)
        FileUtils.symlink(@path, other)
      end

      # Swaps the resouce file and the other resouce file.
      #
      # @param [Local] other
      #   swap target
      def shift_from(other)
        raise ArgumentError.new(other) unless other.kind_of?(self.class)
        unless File.ftype(other.path) == "file"
          raise ArgumentError.new(other)
        end
        dir = @path.dirname
        dir.mkpath unless dir.exist?
        FileUtils.mv(other.path, @path)
      end
    end
  end
end
