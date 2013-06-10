module Pione
  module Option
    # OptionItem is an option item for PIONE command.
    class Item < StructX
      member :name
      member :short
      member :long
      member :desc
      member :default
      member :value
      member :values
      member :action
      member :validator
    end

    # OptionInterface provides basic methods for option modules. All option
    # modules should be extended by this.
    module OptionInterface
      attr_reader :items

      # Define a new option for the command.
      #
      # @param args [Array]
      #   OptionParser arguments
      # @param b [Proc]
      #   option action
      # @return [void]
      def define(name, &b)
        item = Item.new.tap do |item|
          item.name = name
          b.call(item)
        end

        if self.kind_of?(Module)
          singleton_class.send(:define_method, name) {item}
        else
          @items << item
        end
      end

      # Install the option module.
      #
      # @param mod [Module]
      #   PIONE's option set modules
      # @return [void]
      def use(item)
        @items << item
      end
    end
  end
end
