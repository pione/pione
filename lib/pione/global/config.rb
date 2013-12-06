module Pione
  module Global
    # Config is a class for setting PIONE system configuration.
    class Config
      # Load configuration and apply it to global settings.
      def self.load(path)
        new(path).tap {|x| x.apply}
      end

      forward! :@table, "[]", "each"

      # config file path
      attr_reader :path

      # Create a new configuration.
      def initialize(path)
        @path = Pathname.new(path)
        @table = Hash.new
        (@path.exist? ? JSON.load(@path.read) : {}).each do |key, val|
          @table[key.to_sym] = val
        end
        raise InvalidConfigFile.new(@path) unless @table.kind_of?(Hash)
      end

      # Apply config date to global settings.
      def apply
        @table.each do |key, val|
          name = key.to_sym
          if_configurable_item(name) do
            Global.set(name, val)
          end
        end
      end

      # Set the global item.
      #
      # @param name [String]
      #   item name
      # @param value [Object]
      #   item value
      # @return [void]
      def set(name, value)
        raise ArgumentError.new if value.nil?

        name = name.to_sym
        if_configurable_item(name) do
          @table[name] = ValueConverter.convert(Global.item[name].type, value)
        end
      end

      # Get the global item's value.
      #
      # @param name [String]
      #   item name
      # @return [Object]
      #   item value
      def get(name)
        name = name.to_sym
        if_configurable_item(name) do
          @table[name]
        end
      end

      def unset(name)
        name = name.to_sym
        @table.delete(name)
      end

      # Save the configuration items to the file.
      #
      # @param path [Pathname]
      #   file path
      # @return [void]
      def save(path=@path)
        path.open("w+") do |file|
          file.write(JSON.pretty_generate(@table))
        end
      end

      private

      def if_configurable_item(name, &b)
        if Global.item[name] and Global.item[name].configurable?
          b.call
        else
          raise UnconfigurableVariableError.new(name)
        end
      end
    end
  end
end
