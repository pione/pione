module Pione
  # Global is a table of global variables in PIONE system. It defines variable
  # names, initial values, and configuration conditions. You can set and get
  # value by calling item named method.
  module Global
    @__names__ = Array.new           # variable names
    @__configurable__ = Hash.new     # variable configurability
    @__lazy_initializer__ = Hash.new # variable initializers

    class << self
      # Define a new global variable.
      def define_item(name, configurable, initial_value=nil, &initializer)
        # setup informations
        @__names__ << name
        @__configurable__[name]= configurable
        @__lazy_initializer__[name] = initializer if block_given?

        # set reader and writer
        define_variable_reader(name)
        define_variable_writer(name)

        # set initial value
        if initial_value
          set(name, initial_value)
        end
      end

      # Get value of the variable.
      def get(name)
        if val = instance_variable_get("@%s" % name)
          return val
        else
          # call lazy initializer
          if @__lazy_initializer__.has_key?(name)
            instance_variable_set("@%s" % name, @__lazy_initializer__[name].call)
          end
        end
      end

      # Set value of the variable.
      def set(name, val)
        instance_variable_set("@%s" % name, val)
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

require 'pione/global/debug-variable'
require 'pione/global/system-variable'
require 'pione/global/relay-variable'
require 'pione/global/client-variable'
require 'pione/global/task-worker-variable'
require 'pione/global/broker-variable'
require 'pione/global/input-generator-variable'
require 'pione/global/tuple-space-notifier-variable'
