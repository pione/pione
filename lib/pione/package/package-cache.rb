module Pione
  module Package
    # PackageCache is cache mechanism for PIONE package. Cache makes both of PPG
    # package for sharing and directory package for reference.
    module PackageCache
      class << self
        # Cache PPG package and directory package on the location. This method
        # returns directory cache location. If you want to PPG archive cache
        # location, use #ppg(digest).
        def cache(location)
          if location.directory?
            # if it is directory location, make a PPG archive and expand it
            ppg_location = create_ppg_cache_from_directory(location)
            return create_directory_cache(ppg_location)
          else
            # if it is ppg location, copy a PPG archive and expand it
            if /\.ppg$/i.match(location.basename)
              ppg_location = create_ppg_cache_from_ppg(location)
              return create_directory_cache(ppg_location)
            else
              raise InvalidPackage.new("The location \"%s\" is not PPG archive." % location.address)
            end
          end
        end

        # Return true cache that has the digest exists
        def exist?(digest)
          ppg_cache(digest) and directory_cache(digest)
        end

        # Find PPG cache location by the digest.
        def ppg_cache(digest)
          Global.ppg_cache_directory.entries.each do |entry|
            begin
              if digest == PackageFilename.parse(entry.basename).digest
                return entry
              end
            rescue InvalidPackageFilename
              next
            end
          end
          return nil
        end

        # Find directory cache location by the digest.
        def directory_cache(digest)
          location = Global.directory_package_cache_directory + digest
          return location.exist? ? location : nil
        end

        private

        # Create PPG archive cache from the location.
        def create_ppg_cache_from_directory(location)
          PackageArchiver.new(location).archive(Global.ppg_package_cache_directory, true)
        end

        # Create PPG archive cache from the location.
        def create_ppg_cache_from_ppg(location)
          filename = PackageFilename.parse(location.basename)
          filename.digest = Util::PackageDigest.generate(location)
          ppg_cache_location = Global.ppg_package_cache_directory + filename.string
          location.copy(ppg_cache_location)
          return ppg_cache_location
        end

        # Create directory cache from cached PPG archive.
        def create_directory_cache(ppg_location)
          digest = Util::PackageDigest.generate(ppg_location)
          cache_location = Global.directory_package_cache_directory + digest
          unless cache_location.exist?
            PackageExpander.new(ppg_location).expand(cache_location)
          end
          return digest
        end
      end
    end
  end
end
