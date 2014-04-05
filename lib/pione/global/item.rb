module Pione
  module Global
    #
    # variables
    #

    # these variables should be with prefix and postfix because of name colloision
    @item = Hash.new                 # item table
    @__dependencies__ = Hash.new {|h, k| h[k] = []} # dependency table

    class << self
      attr_reader :item
      attr_reader :__dependencies__

      # Define an internal item. The item cannot be configured by user.
      def define_internal_item(name, initial_value=nil, &definition)
        Item.new(name, false).tap do |item|
          definition.call(item) if block_given?
          item.register
        end
      end

      # Define an external item. The item can be configured by user.
      def define_external_item(name, initial_value=nil, &definition)
        Item.new(name, true).tap do |item|
          definition.call(item) if block_given?
          item.register
        end
      end

      # Define a computed item. The item cannote be configured by user.
      def define_computed_item(name, dependencies, &definition)
        Item.new(name, false, :dependencies => dependencies).tap do |item|
          definition.call(item) if block_given?
          item.register
        end
      end

      # Get value of the variable.
      def get(name)
        raise UnknownItem.new(name) unless @item.has_key?(name)

        # get current value
        val = @item[name].value

        if val.nil?
          # call updater
          @item[name].update(@item[name].init)

          # get value
          return @item[name].value
        else
          return val
        end
      end

      # Set value of the variable.
      def set(name, val)
        # set value
        @item[name].update(val)

        # update depended items
        @__dependencies__[name].each do |dependency|
          @item[dependency.name].update(nil)
        end
      end
    end

    class Item
      # item name
      attr_reader :name

      # item value
      attr_reader :value

      # item names that the item depends
      attr_reader :dependencies

      # item description
      attr_accessor :desc

      # initial value
      attr_accessor :init

      # type of item value
      attr_accessor :type

      # update process object
      attr_reader :updater

      # original value
      attr_reader :orig

      # record target
      attr_accessor :record

      def initialize(name, configurable, option={})
        @name = name
        @value = nil
        @configurable = configurable
        @dependencies = option[:dependencies] || []
        @desc = nil
        @init = nil
        @type = nil
        @updater = Proc.new {|val| val}
        @post_action = nil
        @orig = nil
        @record = false
      end

      # Return true if the item is configurable.
      def configurable?
        @configurable
      end

      # Register the item to global system.
      def register
        # register this item
        Global.item[@name] = self

        # build dependency table for computed items
        if @dependencies
          @dependencies.each do |dependency|
            Global.__dependencies__[dependency] << self
          end
        end

        # set reader and writer
        name = @name
        Global.singleton_class.module_eval do |mod|
          define_method(name) {get(name)}
          define_method("set_%s" % name) {|val| set(name, val)}
          define_method("%s=" % name) {|val| set(name, val)}
        end
      end

      # Unregister the item from global system.
      def unregister
        Global.item.delete(@name)

        # remove dependency
        if @dependencies
          @dependencies.each do |dependency|
            Global.__dependencies__.delete(dependency)
          end
        end

        # remove accessors
        name = @name
        Global.singleton_class.module_eval do |mod|
          remove_method(name)
          remove_method("set_%s" % name)
          remove_method("%s=" % name)
        end
      end

      # Define updater process of the item.
      def define_updater(&b)
        @updater = b
      end

      def post(&b)
        @post_action = b
      end

      # Update the item with the value.
      def update(val)
        @orig = val
        @value = @updater.call(ValueConverter.convert(@type, val))
        if @post_action
          @post_action.call(@value)
        end
      end
    end

    module ValueConverter
      def self.convert(type, val)
        case type
        when :string
          val = val.to_s unless val.kind_of?(String)
        when :integer
          val = val.to_i unless val.kind_of?(Integer)
        when :boolean
          val = val == "true" ? true : false unless val == true or val == false
        end

        return val
      end
    end
  end
end
