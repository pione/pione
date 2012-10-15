module Pione
  module Util
    # Config represents a PIONE system configuration.
    class Config < PioneObject
      @@default = {}

      def self.define_time(name, default)
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
      def self.load(path=Pathname.new("~/.pione/config.yml").expand_path)
        self.new(YAML.load(path.read))
      end

      define_item :working_directory, File.join(Dir.tmpdir, "pione-wd")
      define_item :presence_notification_port, 55000
      define_item :tuple_space_provider_druby_port, 54000
      define_item :tuple_space_receiver_druby_port, 54001

      # Creates a new configuration.
      # @param [Hash] data
      #   preset configuration table
      def initialize(data={})
        merge!(data)
      end
    end
  end

  CONFIG = Util::Config.load
end
