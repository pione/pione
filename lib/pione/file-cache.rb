module Pione
  module FileCache
    # Returns file cache class.
    def self.cache_method
      @klass || SimpleCacheMethod
    end

    # Sets file cache class.
    def self.set_cache_method(klass)
      @klass = klass
    end

    # Returns the singleton.
    def self.instance
      @instance ||= cache_method.new
    end

    # Gets cached data path from the uri resource.
    def self.get(uri)
      instance.get(uri)
    end

    # Puts the data to uri resource and caches it.
    def self.put(src, uri)
      instance.put(src, uri)
    end

    def self.shift(old_uri, new_uri)
      instance.shift(old_uri, new_uri)
    end

    class FileCacheMethod
      # Gets the cache location path of the URI.
      def get(uri)
        raise NotImplementedError
      end

      # Puts the file into cache with the URI.
      def put(src, uri)
        raise NotImplementedError
      end

      # Shitfs the URI.
      def shift(old_uri, new_uri)
        raise NotImplementedError
      end
    end

    class SimpleCacheMethod < FileCacheMethod
      def initialize
        @table = {}
        @tmpdir = Dir.mktmpdir("pione-file-cache")
      end

      # Gets cached data path from the uri resource.
      def get(uri)
        # check cached or not
        unless @table.has_key?(uri)
          # prepare cache path
          path = prepare_cache_path

          # link the resource file to cache path
          Resource[uri].link_to(path)
          @table[uri.to_s] = path
        end

        return @table[uri.to_s]
      end

      # Puts the data to uri resource and caches it in local.
      def put(src, uri)
        # prepare cache path
        path = prepare_cache_path

        # move the file from the working directory to cache
        FileUtils.mv(src, path)

        # make a symbolic link
        FileUtils.symlink(path, src)

        # copy from cache to the resource file
        @table[uri.to_s] = path
        Resource[uri].link_from(path)
      end

      def shift(old_uri, new_uri)
        @table[new_uri.to_s] = @table[old_uri.to_s]
      end

      private

      # Makes new cache path.
      def prepare_cache_path
        cache = Tempfile.new("", @tmpdir)
        path = cache.path
        cache.close(true)
        return path
      end
    end
  end
end
