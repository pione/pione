module Pione
  module Package
    # PackageHandler is a set of operations for package.
    class PackageHandler
      class << self
        # Update package info file and scenario info files.
        def write_info_files(location)
          package_info = PackageScanner.new(location).scan
          (location + "pione-package.json").write(JSON.pretty_generate(package_info))
          Log::SystemLog.info("write %s" % (location + "pione-package.json").address)
          package_info.scenarios.each do |scenario|
            scenario_info = ScenarioScanner.new(location + scenario).scan
            ScenarioHandler.new(location + scenario, scenario_info).write_info_file
          end
        end
      end

      attr_reader :location # local package location
      attr_reader :info
      attr_reader :digest
      attr_reader :package_type

      def initialize(location, key={})
        @location = location

        unless key.has_key?(:digest) or key.has_key?(:info)
          raise ArgumentError
        end

        # init with digest
        if digest = key[:digest]
          @digest = digest
          json = (PackageCache.directory_cache(digest) + "pione-package.json").read
          @info = PackageInfo.read(json)
        end

        # init with info for single document location
        if info = key[:info]
          @digest = nil
          @info = info
        end
      end

      # Evaluate the package context in the environment. This method will
      # introduce a new package id, and the context is evaluated under it.
      def eval(env)
        # load parent packages
        parent_package_ids = @info.parents.map do |parent_info|
          load_parent_package(env, parent_info.name, parent_info.edition, parent_info.tag)
        end

        # load this package
        _env = env.setup_new_package(info.name || "Anonymous", parent_package_ids)
        @info.documents.inject(Lang::PackageContext.new) do |_context, d|
          Document.load(_env, @location + d, @info.name, @info.edition, @info.tag, d)
        end

        return _env
      end

      # Upload the package files to the location.
      def upload(dest)
        @info.bins.each do |entry|
          (@location + entry).copy(dest + entry)
        end
      end

      # Find scenario that have the name.
      #
      # @param name [String]
      #   scenario name
      # @return [ScenarioHandler]
      #   the scenario handler
      def find_scenario(name)
        @info.scenarios.each do |path|
          if name == :anything
            # read first hit scenario
            return ScenarioReader.read(@location + path)
          else
            # read matched scenario
            scenario = ScenarioReader.read(@location + path)
            if scenario.info.name == name
              return scenario
            end
          end
        end
      end

      private

      # Load parent packages from package database. Parent packages should be
      # recorded in the database, or Package::NotFound error is raised.
      def load_parent_package(env, name, edition, tag)
        if digest = Global.package_database.find(name, edition, tag)
          parent_location = PackageCache.directory_cache(digest)
          handler = PackageHandler.new(parent_location, digest: digest)
          handler.eval(env)
          return env.current_package_id
        else
          raise NotFound.new(name, edition, tag)
        end
      end
    end
  end
end

