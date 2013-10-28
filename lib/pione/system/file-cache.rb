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

      # Synchronize cache of old location with new location.
      #
      # @param old_location [BasicLocation]
      #   old data location
      # @param new_location [BasicLocation]
      #   new data location
      # @return [void]
      def self.sync(old_location, new_location)
        instance.sync(old_location, new_location)
      end

      # Return true if the location is cached.
      #
      # @return [Boolean]
      #   true if the location is cached
      def self.cached?(location)
        instance.cached?(location)
      end

      # Clear cache.
      #
      # @return [void]
      def self.clear
        instance.clear
      end

      # FileCache is an interface class of cache methods.
      class FileCacheMethod
        # Get the cache path of the location.
        #
        # @param location [BasicLocation]
        #   data location
        # @return [BasicLocalLocation]
        #   cached path
        def get(location)
          raise NotImplementedError
        end

        # Put and cache the source data at the location.
        #
        # @param src [BasicLocation]
        #   source path
        # @param location [BasicLocation]
        #   destination
        # @return [void]
        def put(src, location)
          raise NotImplementedError
        end

        # Synchronize cache of old location with new location.
        #
        # @param old_location [BasicLocation]
        #   old data location
        # @param new_location [BasicLocation]
        #   new data location
        # @return [void]
        def sync(old_location, new_location)
          raise NotImplementedError
        end

        # Return true if the location is cached.
        #
        # @return [Boolean]
        #   true if the location is cached
        def cached?(location)
          raise NotImplementedError
        end

        # Clear cache.
        #
        # @return [void]
        def clear
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
          # cache if record doesn't exist
          unless @table.has_key?(location)
            cache_location = Location[Global.file_cache_path_generator.create]
            location.turn(cache_location)
            @table[location] = cache_location
          end
          unless @table[location].exist?
            location.turn(@table[location])
          end
          return @table[location]
        end

        def put(src, dest)
          # make cache from source and link between cache and destination
          @table[dest] = get(src).tap{|cache_location| cache_location.turn(dest)}
        end

        def sync(old_location, new_location)
          if cache_location = @table[old_location]
            @table[new_location] = cache_location
          end
        end

        def cached?(location)
          @table.has_key?(location)
        end

        def clear
          @table.clear
        end
      end
    end
  end
end
