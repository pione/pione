module Pione
  module Package
    # PackageReader is a reader for packages.
    class PackageReader
      class << self
        # Read a pacakge from the location.
        def read(location)
          case PackageTypeClassifier.classify(location)
          when :directory
            DirectoryPackageReader.new(location).read
          when :git
            GitPackageReader.new(location).read
          when :archive
            ArchivePackageReader.new(location).read
          when :document
            SingleDocumentPackageReader.new(location).read
          end
        end
      end

      def initialize(location)
        @location = location
        @local = nil
        @package_info = read_package_info
      end

      def read
        raise NotImplementedError
      end

      private

      # Read informations from the package location.
      def read_package_info
        PackageInfo.load((@location + "pione-package.json").read)
      rescue Location::NotFound
        raise InvalidPackage.new(self, "pione-package.json not found in %s" % @location.uri)
      end

      #
      # @return [Package]
      #   the package
      def read_document
        opt = {package_name: "Anonymous", filename: @location.basename}
        context = Document.load(@location, opt)
        Package.new(info: {"PackageName" => "Anonymous"}, context: context)
      end

      # Find scenarios from the package location.
      #
      # @return [Array<PackageScenario>]
      #   scenarios
      def find_scenario_paths(scenarios)
        return [] if scenarios.nil?
        scenarios.select do |path|
          (@location + path + "scenario.yml").exist?
        end.uniq.compact
      end
    end

    # PackageTypeClassifier provides the function to distinguish package types.
    module PackageTypeClassifier
      class << self
        # Distinguish the type of package based on the location.
        #
        # @param [BasicLocation]
        #   location of the package
        # @return [Symbol]
        #   package type
        def classify(location)
          return :git if git?(location)
          return :archive if archive?(location)
          return :document if document?(location)
          return :directory
        end

        private

        # Return true if the location represents git package.
        def git?(location)
          location.location_type == :git_repository
        end

        # Return true if the location represents archive package.
        def archive?(location)
          location.file? and location.extname == ".ppg"
        end

        # Return true if the location represents document package.
        def document?(location)
          location.file? and location.extname == ".pione"
        end
      end
    end

    # DirectoryPackageReader reads package structure from directory based
    # package.
    class DirectoryPackageReader < PackageReader
      def initialize(location)
        @location = location
      end

      def read
        # copy to local
        local_location = make_local_location

        # cache
        digest = PackageCache.cache(local_location)

        PackageHandler.new(PackageCache.directory_cache(digest), digest: digest)
      end

      def make_local_location
        # make temporary directory
        local_location = Location[Temppath.create]

        # copy files to local

        # pione-package.json
        info = PackageInfo.read((@location + "pione-package.json").read)
        (@location + "pione-package.json").copy(local_location + "pione-package.json")

        # documents
        (info.documents + info.bins).each do |path|
          (@location + path).copy(local_location + path)
        end

        # scenarios
        info.scenarios.each do |path|
          scenario_info = ScenarioInfo.read((@location + path + "pione-scenario.json").read)
          (@location + path + "pione-scenario.json").copy(local_location + path + "pione-scenario.json")
          (@location + path + "Scenario.pione").copy(local_location + path + "Scenario.pione")
          (scenario_info.inputs + scenario_info.outputs).each do |_path|
            (@location + path + _path).copy(local_location + path + _path)
          end
        end

        return local_location
      rescue Location::LocationError => e
        raise InvalidPackage.new("package \"%s\" is invalid: %s" % [@location.address, e.message])
      end
    end

    # GitPackageReader is a reader for git based package.
    class GitPackageReader < PackageReader
      def initialize(location)
        @location = location
      end

      def read
        local_location = make_local_location
        digest = PackageCache.cache(local_location)
        return PackageHandler.new(PackageCache.directory_cache(digest), digest: digest)
      end

      private

      def make_local_location
        # we should use local cloned repository, but currently export
        local_location = Location[Temppath.mkdir]
        @location.export(local_location)
        return local_location
      end
    end

    # ArchivePackageReader is a reader for PPG pakage.
    class ArchivePackageReader < PackageReader
      def initialize(location)
        @location = location # arbitrary data location
      end

      def read
        # copy to local, we cannot use Location::DataLocation#local in here
        # because the method don't keep filename
        local_location = Location[Temppath.mkdir] + @location.basename
        @location.copy(local_location)

        # cache the package
        digest = PackageCache.cache(local_location)

        return PackageHandler.new(PackageCache.directory_cache(digest), digest: digest)
      end
    end

    # SingleDocumentPackageReader is a reader for single document package.
    class SingleDocumentPackageReader < PackageReader
      def initialize(location)
        @location = location
      end

      def read
        # copy to local
        local_location = @location.local

        # make package info by scanning annotations
        info = PackageScanner.new(local_location).scan

        return PackageHandler.new(local_location.dirname, info: info)
      end
    end
  end
end
