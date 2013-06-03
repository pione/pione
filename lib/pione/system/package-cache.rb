module Pione
  module System
    class PackageCache
      TABLE = {}

      class << self
        def get(package_name, base_location)
          if TABLE.has_key?(package_name)
            TABLE[package_name]
          else
            TABLE[package_name] = PackageCache.new(package_name, base_name)
          end
        end
      end
    end
  end
end

