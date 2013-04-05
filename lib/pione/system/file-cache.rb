module Pione
  module System
    # FileCache is a caching system for task workers.
    module FileCache
      # Return file cache class.
      #
      # @return [Class]
      #   CacheMethod class
      def self.cache_method
        @klass || SimpleCacheMethod
      end

      # Set a file cache class.
      #
      # @param klass [Class]
      #   CacheMethod class
      # @return [void]
      def self.set_cache_method(klass)
        @klass = klass
      end

      # Return the singleton.
      #
      # @return [CacheMethod]
      #   cache method instance
      def self.instance
        @instance ||= cache_method.new
      end

      # Get cached data path from the uri resource.
      #
      # @param location [BasicLocation]
      #   data location
      # @return [Pathname]
      #   cached path
      def self.get(location)
        instance.get(location)
      end

      # Put the data to the location and caches it.
      #
      # @param src [String]
      #   source path
      # @param location [BasicLocation]
      #   destination location
      # @return [void]
      def self.put(src, location)
        instance.put(src, location)
      end

      # Shift the resource from old uri to new uri.
      #
      # @param old_location [BasicLocation]
      #   old data location
      # @param new_location [BasicLocation]
      #   new data location
      # @return [void]
      def self.shift(old_location, new_location)
        instance.shift(old_location, new_location)
      end

      # FileCache is an interface class of cache methods.
      class FileCacheMethod
        # Get the cache path of the location.
        #
        # @param location [BasicLocation]
        #   data location
        # @return [Pathname]
        #   cached path
        def get(location)
          raise NotImplementedError
        end

        # Cache the source data of the location.
        #
        # @param src [Pathname]
        #   source path
        # @param location [BasicLocation]
        #   destination
        # @return [void]
        def put(src, location)
          raise NotImplementedError
        end

        # Shift the data.
        #
        # @param old_location [BasicLocation]
        #   old resource location
        # @param new_location [BasicLocation]
        #   new resource location
        # @return [void]
        def shift(old_location, new_location)
          raise NotImplementedError
        end
      end

      # SimpleCacheMethod is a simple cache method implementation.
      class SimpleCacheMethod < FileCacheMethod
        # Creates a method.
        def initialize
          @table = {}
          @tmpdir = Global.file_cache_directory
        end

        def get(location)
          raise ArgumentError.new(location) unless location.kind_of?(Location::BasicLocation)

          # check cached or not
          unless @table.has_key?(location)
            # prepare cache path
            path = prepare_cache_path

            # link the file to cache path
            location.link_to(path)
            @table[location] = path
          end

          return @table[location]
        end

        def put(src, location)
          raise ArgumentError.new(src) unless src.kind_of?(Pathname)
          raise ArgumentError.new(location) unless location.kind_of?(Location::BasicLocation)

          # prepare cache path
          path = prepare_cache_path

          # move the file from the working directory to cache
          FileUtils.mv(src, path)

          # make a symbolic link from original location to the cache
          FileUtils.symlink(path, src)

          # copy from cache to the file
          @table[location] = path
          location.link_from(path)
        end

        def shift(old_location, new_location)
          raise ArgumentError.new(old_location) unless old_location.kind_of?(Location::BasicLocation)
          raise ArgumentError.new(new_location) unless new_location.kind_of?(Location::BasicLocation)

          if path = @table[old_location]
            if new_location.kind_of?(Location::LocalLocation)
              FileUtils.symlink(new_location.path, path, :force => true)
            end
            @table[new_location] = path
          end
        end

        private

        # Make new cache path.
        #
        # @return [Pathname]
        #   cache path
        def prepare_cache_path
          cache = Tempfile.new("", Global.file_cache_directory)
          path = Pathname.new(cache.path)
          cache.close(true)
          return path
        end
      end
    end
  end
end
