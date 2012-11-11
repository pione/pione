module Pione
  module CommandOption
    module OptionInterface
      # @api private
      def self.extended(klass)
        klass.instance_variable_set(:@command_options, {})
      end

      # Defines an option for the command.
      # @return [void]
      def define_option(*args, &b)
        @command_options[args.first] = [args, b]
      end

      # Removes the option.
      # @return [void]
      def remove_option(name)
        @command_options.delete(name)
      end

      # Returns the command options.
      # @return [Array]
      def command_options
        @command_options
      end

      # Installs the option module.
      # @return [void]
      def use_option_module(mod)
        @command_options = @command_options.update(mod.command_options)
      end
    end

    class BasicOption
      extend OptionInterface

      def self.inherited(klass)
        klass.instance_variable_set(:@command_options, command_options.clone)
      end
    end
  end
end
