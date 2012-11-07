module Pione
  module System
    # FileCache is a caching system for task workers.
    module FileCache
      # Returns file cache class.
      # @return [Class]
      #   CacheMethod class
      def self.cache_method
        @klass || SimpleCacheMethod
      end

      # Sets a file cache class.
      # @param [Class] klass
      #   CacheMethod class
      # @return [void]
      def self.set_cache_method(klass)
        @klass = klass
      end

      # Returns the singleton.
      # @return [CacheMethod]
      #   cache method instance
      def self.instance
        @instance ||= cache_method.new
      end

      # Gets cached data path from the uri resource.
      # @param [String] uri
      #   uri to get
      # @return [String]
      #   cached path string
      def self.get(uri)
        instance.get(uri)
      end

      # Puts the data to uri resource and caches it.
      def self.put(src, uri)
        instance.put(src, uri)
      end

      # Shifts the resource from old uri to new uri.
      # @param [String] old_uri
      #   old resource uri
      # @param [String] new_uri
      #   new resource uri
      # @return [void]
      def self.shift(old_uri, new_uri)
        instance.shift(old_uri, new_uri)
      end

      # FileCache is an interface class of cache methods.
      class FileCacheMethod
        # Gets the cache location path of the URI.
        # @param [String] uri
        #   resource uri
        # @return [String]
        #   cached path
        def get(uri)
          raise NotImplementedError
        end

        # Puts the file into cache with the URI.
        # @return [void]
        def put(src, uri)
          raise NotImplementedError
        end

        # Shitfs the URI.
        # @param [String] old_uri
        #   old resource uri
        # @param [String] new_uri
        #   new resource uri
        # @return [void]
        def shift(old_uri, new_uri)
          raise NotImplementedError
        end
      end

      # SimpleCacheMethod is a simple cache method implementation.
      class SimpleCacheMethod < FileCacheMethod
        # Creates a method.
        def initialize
          @table = {}
          @tmpdir = Dir.mktmpdir("pione-file-cache")
        end

        # Gets cached data path from the uri resource.
        # @param [String] uri
        #   resource uri
        # @return [String]
        #   cached path
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
        # @return [void]
        def put(src, uri)
          # prepare cache path
          path = prepare_cache_path

          # move the file from the working directory to cache
          FileUtils.mv(src, path)

          # make a symbolic link from original location to the cache
          FileUtils.symlink(path, src)

          # copy from cache to the resource file
          @table[uri.to_s] = path
          Resource[uri].link_from(path)
        end

        # @param [String] old_uri
        #   old resource uri
        # @param [String] new_uri
        #   new resource uri
        # @return [void]
        def shift(old_uri, new_uri)
          if path = @table[old_uri.to_s]
            if new_uri.scheme == "local"
              FileUtils.symlink(new_uri.path, path, :force => true)
            end
            @table[new_uri.to_s] = path
          end
        end

        private

        # Makes new cache path.
        # @api private
        def prepare_cache_path
          cache = Tempfile.new("", @tmpdir)
          path = cache.path
          cache.close(true)
          return path
        end
      end
    end
  end
end
