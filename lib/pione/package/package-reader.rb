module Pione
  module Package
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

    # PackageReader is a reader for packages.
    class PackageReader
      class << self
        # Read a pacakge from the location.
        def read(location)
          new(location).read
        end
      end

      attr_reader :location
      attr_reader :type

      # @param location [BasicLocation]
      #   package location
      def initialize(location)
        @location = location
        @type = PackageTypeClassifier.classify(location)
      end

      def read
        case @type
        when :directory
          read_directory
        when :git
          read_git
        when :archive
          read_archive
        when :document
          read_document
        end
      end

      private

      # Return the location of package information file.
      def spec_location
        @location + "package.yml"
      end

      # Read package directory.
      #
      # @return [Package]
      #   the package
      def read_directory
        info = read_package_info
        Package.new(
          location: @location,
          info: info,
          bin: @location + "bin",
          context: create_context(info["PackageName"], info["Documents"]),
          document_paths: info["Documents"],
          scenario_paths: find_scenario_paths(info["Scenarios"])
        )
      end

      # Read git package.
      def read_git
        GitPackageReader.read(@location)
      end

      # Read PIONE archive.
      #
      # @return [Package]
      #   the package
      def read_archive
        self.class.read(ArchivePackageReader.read(@location))
      end

      # Read PIONE document.
      #
      # @return [Package]
      #   the package
      def read_document
        opt = {package_name: "Anonymous", filename: @location.basename}
        context = Document.load(@location, opt)
        Package.new(info: {"PackageName" => "Anonymous"}, context: context)
      end

      # Read the informations from the package location.
      #
      # @return [Hash]
      #   package information table
      def read_package_info
        YAML.load((@location + "package.yml").read)
      rescue Location::NotFound
        raise InvalidPackageError.new(self, "package.yml not found in %s" % @location.uri)
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

      # Find documents from the packcage location.
      def create_context(package_name, document_names)
        document_names.inject(Lang::PackageContext.new) do |context, name|
          opt = {package_name: package_name, filename: name}
          context + Document.load(@location + name, opt)
        end
      end
    end

    # PackageScenarioReader is a reader for loading scenarios.
    class PackageScenarioReader
      # Read scenario from the location.
      def self.read(location, package_path)
        new(location, package_path).read
      end

      attr_reader :location
      attr_reader :package_path

      # @param location [Location]
      #   the scenario location
      def initialize(location, package_path)
        @location = location
        @package_path = package_path
      end

      # Return the location of scenario information file.
      def info_location
        @location + @package_path + "scenario.yml"
      end

      # Read scenario files.
      #
      # @return [PackageScenario]
      #   the scenario
      def read
        begin
          info = read_scenario_informations
          PackageScenario.new(@location, @package_path, info)
        rescue
          nil
        end
      end

      private

      # Read scenario informations.
      #
      # @return [Hash]
      #   scenario information table
      def read_scenario_informations
        path = info_location
        if path.exist?
          YAML.load(path.read)
        else
          {"ScenarioName" => (@location + @package_path).basename}
        end
      end
    end

    class GitPackageReader
      class << self
        def read(location)
          new(location).read
        end
      end

      def initialize(location, option={})
        @location = location
        @package_name = option[:package_name]
        @edition = option[:edition] || "origin"
        @branch = option[:branch]
        @tag = option[:tag]
        @hash_id = option[:hash_id]

        @digest = Digest::SHA1.hexdigest(@location.address)
      end

      def read
        if cache_location = find_cache_location
          return PackageReader.read(cache_location)
        else
          Location[Temppath.mkdir].tap do |tmp|
            @location.export(tmp)
            _package = PackageReader.read(tmp)
            cache_location = Global.git_package_directory + dirname(_package)
            cache_location.mkdir
            tmp.entries.each {|entry| entry.move(cache_location)}
            return PackageReader.read(cache_location)
          end
        end
      end

      private

      def find_cache_location
        begin
          Global.git_package_directory.entries.find do |entry|
            entry.basename.to_s.split("_").last.include?(@location.compact_hash_id)
          end
        rescue Pione::Location::NotFound
          return nil
        end
      end

      # Return the cache directory name.
      def dirname(package)
        "%s(%s)_%s" % [package.name, package.edition, @location.compact_hash_id]
      end
    end

    class ArchivePackageReader
      class << self
        def read(location)
          new(location).expand
        end
      end

      def initialize(location)
        @location = location
      end

      def expand
        cache = Global.archive_package_cache_dir + cache_name
        PackageExpander.new(@location).expand(cache)
        return cache
      end

      def cache_name
        fname = PackageFilename.parse(@location.basename)
        "%s(%s)_%s" % [fname.package_name, fname.edition, @location.sha1]
      end
    end
  end
end
