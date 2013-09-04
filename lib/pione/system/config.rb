module Pione
  module System
    # Config is a class for setting PIONE system configuration.
    class Config
      # Load configuration and apply it to global settings.
      def self.load(path)
        new(path).tap {|x| x.apply}
      end

      forward :@table, "[]"

      # config file path
      attr_reader :path

      # Create a new configuration.
      def initialize(path)
        @path = Pathname.new(path)
        @table = @path.exist? ? YAML.load(@path.read) : {}
        raise InvalidConfigFile.new(@path) unless @table.kind_of?(Hash)
      end

      # Apply config date to global settings.
      def apply
        @table.each do |key, val|
          key = key.to_sym
          if Global.all_names.include?(key) and Global.configurable?(key)
            Global.set(key, val)
          else
            raise UnconfigurableVariableError.new(key)
          end
        end
      end
    end
  end
end
