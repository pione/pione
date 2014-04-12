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

      # Set a file cache method.
      #
      # @param klass [Class]
      #   CacheMethod class
      # @return [void]
      def self.set_cache_method(file_cache_method)
        case file_cache_method
        when Symbol
          if klass = @file_cache_method[file_cache_method]
            @klass = klass
          else
            raise ArgumentError.new(file_cache_method)
          end
        when Class
          @klass = file_cache_method
        else
          raise ArgumentError.new(file_cache_method)
        end
      end

      # Return the singleton.
      #
      # @return [CacheMethod]
      #   cache method instance
      def self.instance
        @instance ||= cache_method.new
      end

      # Get cached data location of the location. If the location is not cached
      # and needs to be cached, create the cache and return it. If not, return
      # the location as is.
      #
      # @param location [BasicLocation]
      #   data location
      # @return [BasicLocation]
      #   cached location
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

      # Register the file cache method with the name.
      #
      # @param name [Symbol]
      #   the name of file cache method
      # @param klass [FileCacheMethod]
      #   file cache method class
      # @return [void]
      def self.register_file_cache_method(name, klass)
        (@file_cache_method ||= {})[name] = klass
      end

      # FileCache is an interface class of cache methods.
      class FileCacheMethod
        # Name the file cache method class.
        #
        # @param name [String]
        #   cache mtehod name
        def self.set_name(name)
          @name = name
          FileCache.register_file_cache_method(name, self)
        end

        # Return the name.
        #
        # @return [String] the name
        def self.name
          @name
        end

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
        set_name :simple

        # Creates a method.
        def initialize
          @table = {}
          @tmpdir = Global.file_cache_directory
        end

        def get(location)
          # cache if record doesn't exist
          unless @table.has_key?(location)
            if not(location.local?)
              # create a cache and copy the location data to it
              cache_location = Location[Global.file_cache_path_generator.create]
              location.copy(cache_location)
              @table[location] = cache_location
            else
              # refer directly if the location is in local
              @table[location] = location
            end
          end
          unless @table[location].exist?
            location.turn(@table[location])
          end
          return @table[location]
        end

        def put(src, dest)
          cache_location = @table[dest]

          # update cache if
          if cache_location.nil? or src.mtime > cache_location.mtime
            cache_location = Location[Global.file_cache_path_generator.create]
            src.copy(cache_location)
            @table[dest] = cache_location
          end
        end

        def sync(old_location, new_location)
          if cached?(old_location)
            @table[new_location] = @table[old_location]
          end
        end

        def cached?(location)
          @table.has_key?(location)
        end

        def clear
          @table.clear
        end
      end

      # NoCacheMethod is a cache method for disabling file caching.
      class NoCacheMethod < FileCacheMethod
        set_name :no_cache

        def get(location)
          location
        end

        def put(src, location)
          # do nothing
        end

        def sync(old_location, new_location)
          # do nothing
        end

        def cached?(location)
          false
        end

        def clear
          # do nothing
        end
      end
    end
  end
end
