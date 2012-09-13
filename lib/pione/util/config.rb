module Pione
  module Util
    include Singleton

    # Config represents a PIONE system configuration.
    class Config < Hash
      # Loads a configuration file formatted by YAML.
      # @param [Pathname] path
      #   configuration file path
      # @return [void]
      def self.load(path=Pathname.new("~").expand_path)
        CONFIG.merge!(YAML.load(path.read))
      end

      # Creates a new configuration.
      # @param [Hash] data
      #   preset configuration table
      def initialize(data={})
        merge!(data)
      end

      # Returns working directory path for task workers.
      # @return [Pathname]
      #   working directory path
      def working_directory
        unless @working_directory
          tmpdir = CONFIG[:working_dir] || Dir.tmpdir
          @working_directory = Pathname.new(Dir.mktmpdir("", tmpdir))
        end
        return @working_directory
      end
    end
  end
end
