module Pione
  # Global is a table of global variables in PIONE system. It defines variable
  # names, initial values, and configuration conditions. You can set and get
  # value by calling item named method.
  module Global
    #
    # variables
    #

    # these variables should be with prefix and postfix because of name colloision
    @__names__ = Array.new           # variable names
    @__configurable__ = Hash.new     # variable configurability
    @__lazy_initializer__ = Hash.new # variable initializers
    @__dependencies__ = Hash.new {|h, k| h[k] = []} # dependency table
    @__updater__ = Hash.new          # updaters for computed item

    class << self
      # Define an internal item. The item cannot be configured by user.
      def define_internal_item(name, initial_value=nil, &initializer)
        define_item(name, false, initial_value, :initializer => initializer)
      end

      # Define an external item. The item can be configured by user.
      def define_external_item(name, initial_value=nil, &initializer)
        define_item(name, true, initial_value, :initializer => initializer)
      end

      # Define a computed item. The item cannote be configured by user.
      def define_computed_item(name, dependencies, &updater)
        define_item(name, false, nil, :dependencies => dependencies, :updater => updater)
      end

      # Get value of the variable.
      def get(name)
        val = instance_variable_get("@%s" % name)

        # call lazy initializer
        if val.nil? and @__lazy_initializer__.has_key?(name)
          set(name, @__lazy_initializer__[name].call)
          return instance_variable_get("@%s" % name)
        end

        # call initial updater
        if val.nil? and @__updater__.has_key?(name)
          update(name)
          return instance_variable_get("@%s" % name)
        end

        return val
      end

      # Set value of the variable.
      def set(name, val)
        # set value
        instance_variable_set("@%s" % name, val)

        # update dependecies
        @__dependencies__[name].each do |dependency|
          update(dependency)
        end
      end

      # Update the computed item.
      def update(name)
        set(name, @__updater__[name].call)
      end

      # Return true if the variable is configurable.
      def configurable?(name)
        @__configurable__[name]
      end

      # Return all variable names.
      def all_names
        @__names__
      end

      private

      # Define a new global variable.
      def define_item(name, configurable, initial_value=nil, option)
        # setup informations
        @__names__ << name
        @__configurable__[name]= configurable
        @__lazy_initializer__[name] = option[:initializer] if option[:initializer]
        @__updater__[name] = option[:updater] if option[:updater]

        # build dependency table for computed items
        if option[:dependencies]
          option[:dependencies].each do |dependency|
            @__dependencies__[dependency] << name
          end
        end

        # set reader and writer
        define_variable_reader(name)
        define_variable_writer(name)

        # set initial value
        unless initial_value.nil?
          set(name, initial_value)
        end
      end

      # Define reader method of the variable.
      def define_variable_reader(name)
        singleton_class.module_eval do |mod|
          define_method(name) {get(name)}
        end
      end

      # Define writer method of the variable.
      def define_variable_writer(name)
        singleton_class.module_eval do |mod|
          define_method("set_%s" % name) {|val| set(name, val)}
          define_method("%s=" % name) {|val| set(name, val)}
        end
      end
    end
  end
end

require 'pione/global/system-variable'
require 'pione/global/path-variable'
require 'pione/global/network-variable'
require 'pione/global/log-variable'
require 'pione/global/relay-variable'
require 'pione/global/client-variable'
require 'pione/global/task-worker-variable'
require 'pione/global/broker-variable'
require 'pione/global/input-generator-variable'
require 'pione/global/tuple-space-notifier-variable'
require 'pione/global/package-variable'
