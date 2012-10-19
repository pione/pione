module Pione
  module Util
    # Config represents a PIONE system configuration.
    class Config < PioneObject
      @@default = {}

      def self.define_item(name, default)
        @@default[name] = default

        define_method(name) do
          self[name]
        end

        define_method("%s=" % name) do |val|
          self[name] = val
        end
      end

      # Loads a configuration file formatted by YAML.
      # @param [Pathname] path
      #   configuration file path
      # @return [void]
      def self.load(path)
        self.new(YAML.load(path.read))
      end

      define_item :enable_tuple_space_provider, false

      define_item :working_directory, Dir.mktmpdir(nil, File.join(Dir.tmpdir, "pione-wd"))
      define_item :tuple_space_provider_druby_port, 54000
      define_item :tuple_space_receiver_druby_port, 54001
      define_item :relay_port, 54002
      define_item :presence_port, 55000

      # Creates a new configuration.
      # @param [Hash] data
      #   preset configuration table
      def initialize(data={})
        @table = {}
        @table.merge!(data)
      end

      # Returns the configuration value or default value.
      # @param [Symbol] key
      #   key symbol
      # @return [Object]
      #   the value
      def [](key)
        @table.has_key?(key) ? @table[key] : @@default[key]
      end

      def []=(key, val)
        @table[key] = val
      end
    end
  end

  path = Pathname.new("~/.pione/config.yml").expand_path
  CONFIG = path.exist? ? CONFIG = Util::Config.load(path) : Util::Config.new
end
