module Pione
  module Resource
    # Local represents local path resources.
    class Local < BasicResource
      # Creates a local resource handler with URI.
      # @param [String, URI] uri
      #   URI of a local path
      def initialize(uri)
        @uri = uri.kind_of?(::URI::Generic) ? uri : ::URI.parse(uri)
        raise ArgumentError unless @uri.kind_of?(URIScheme::LocalScheme)
        @path = Pathname.new(uri.path)
      end

      # (see BasicResource#create)
      def create(data)
        @path.dirname.mkpath unless @path.dirname.exist?
        @path.open("w+"){|file| file.write(data)}
      end

      # (see BasicResource#read)
      def read
        @path.exist? ? @path.read : (raise NotFound.new(@uri))
      end

      # (see BasicResource#update)
      def update(data)
        if @path.exist?
          @path.open("w+"){|file| file.write(data)}
        else
          raise NotFound.new(@uri)
        end
      end

      # (see BasicResource#delete)
      def delete
        @path.delete if @path.exist?
      end

      # (see BasicResource#mtime)
      def mtime
        @path.mtime
      end

      # (see BasicResource#entries)
      def entries
        @path.entries.select{|entry| (@path + entry).file?}.map do |entry|
          Resource[::URI.parse("local:%s" % (@path + entry).expand_path)]
        end
      end

      # (see BasicResource#basename)
      def basename
        @path.basename.to_s
      end

      # (see BasicResource#exist?)
      def exist?
        @path.exist?
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
        dir = @path.dirname
        dir.mkpath unless dir.exist?
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
        dir = @path.dirname
        dir.mkpath unless dir.exist?
        FileUtils.mv(other.path, @path)
      end
    end

    @@schemes['local'] = Local
  end
end
