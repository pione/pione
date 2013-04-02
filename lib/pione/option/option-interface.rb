module Pione
  module Option
    # OptionInterface provides basic methods for option modules. All option
    # modules should be extended by this.
    module OptionInterface
      # Make an array of definitions.
      #
      # @api private
      def self.extended(obj)
        obj.instance_variable_set(:@definitions, [])
        obj.instance_variable_set(:@default_table, {})
        obj.instance_variable_set(:@validators, [])
      end

      attr_reader :definitions
      attr_reader :default_table
      attr_reader :validators

      # Define default value of the option data set.
      #
      # @param name [Symbol]
      #   option data key
      # @param value [Object]
      #   option data value
      # @return [void]
      def default(name, value)
        @default_table[name] = value
      end

      # Define a new option for the command.
      #
      # @param args [Array]
      #   OptionParser arguments
      # @param b [Proc]
      #   option action
      # @return [void]
      def option(*args, &b)
        @definitions << [args, b]
      end

      # Remove the option.
      #
      # @param b [Proc]
      #   remove options that match proc's result
      # @return [void]
      def remove_option(&b)
        @definitions.select! do |definition|
          not(b.call(definition))
        end
      end

      # Install the option module.
      #
      # @param mod [Module]
      #   PIONE's option set modules
      # @return [void]
      def use(mod)
        @definitions += mod.definitions
        @default_table.merge!(mod.default_table)
        @validators += mod.validators
      end

      # Define validation of the option set.
      #
      # @param b [Proc]
      #   validation content
      # @return [void]
      def validate(&b)
        @validators << b
      end
    end
  end
end
