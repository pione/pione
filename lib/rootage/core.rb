module Rootage
  # `Item` is an atomic unit of Rootage, for holding infomations and processes.
  class Item < StructX
    # `name` is item name. This is used as a reference at controller.
    member :name

    # Attribute name in model.
    member :key_name

    # The action's description, this is shown in verbose help.
    member :desc

    # Process context class, instance of this class is used as context of
    # process. This context class should inherit `ProcessContext`.
    member :process_context_class

    # Processes, this includes blocks that is definded by #define_process,
    # #define_assignment, and #define_condition
    member :processes, :default => lambda {[]}

    # Exception handlers.
    member :exception_handlers, :default => lambda {[]}

    # Validators of the item.
    member :validators

    # Define a process that is executed just after pre-process. This is used
    # for setting values excluding command model, for example global values.
    #
    # @yieldparam val [Object]
    #   arbitrary value, this is passed from #execute
    def process(&block)
      self.processes << Proc.new do |scenario, args|
        catch(:rootage_process_failure) do
          get_process_context_class(scenario).new(scenario).instance_exec(*args, &block)
        end
      end
    end

    # Define an assignment process. This assigns the result value of the block
    # to model. This is same as #action excluding model assignment.
    #
    # @param name [Symbol]
    #   key name for model
    # @yieldparam val [Object]
    #   normalized option value
    def assign(name=self.key, &block)
      self.processes << Proc.new do |scenario, args|
        catch(:rootage_process_failure) do
          res = get_process_context_class(scenario).new(scenario).instance_exec(*args, &block)
          if name
            scenario.model[name] = res
          end
        end
      end
    end

    # Define a condition. This is a process simply, but quits the action halfway
    # if it fails.
    #
    # @yieldparam val [Object]
    #   arbitrary value, this is passed from #execute
    def condition(&block)
      self.processes << Proc.new do |scenario, args|
        res = catch(:rootage_process_failure) do
          get_process_context_class(scenario).new(scenario).instance_exec(*args, &block)
          true
        end
        throw :rootage_item_stop unless res
      end
    end

    # Define an exception handler.
    #
    # @param exceptions [Array<Class>]
    #   exception classes that handler should handle, that is assumed `StandardError` if empty
    # @yieldparam e [Exception]
    #   raised exception object
    # @yieldparam args [Array]
    #   arbitrary objects
    def exception(*exceptions, &block)
      if exceptions.empty?
        exceptions = [StandardError]
      end
      self.exception_handlers << ExceptionHandler.new(exceptions, block)
    end

    # Copy the object. This is shallow copy, but arrays are cloned.
    #
    # @return [Item]
    #   copied object
    def copy
      self.class.new.tap do |obj|
        self.each_pair do |key, val|
          obj.set(key => (val.is_a?(Array) or val.is_a?(Hash)) ? val.clone : val)
        end
      end
    end

    # Execute the action.
    #
    # @param scenario [Scenario]
    #   scenario
    # @param args [Array]
    #   arbitrary objects, this is passed to process's block
    # @return [void]
    def execute(scenario, *args)
      catch(:rootage_item_stop) do
        processes.each {|block| self.instance_exec(scenario, args, &block)}
      end
    rescue Exception => e
      catch(:rootage_item_stop) do
        if exception_handlers.find do |handler|
            catch(:rootage_process_failure) do
              handler.try_to_handle(get_process_context_class(scenario).new(scenario), e, args)
            end
          end
        else
          raise
        end
      end
    end

    # Return the key of model.
    def key
      (key_name || name).to_sym
    end

    private

    def get_process_context_class(scenario)
      process_context_class || scenario.process_context_class
    end
  end

  # CollectionInterface provides the way to create item colloction modules.
  #
  # @example
  #    module NewCollection
  #      extend CollectionInterface
  #      set_item_class SomeItem
  #    
  #      define(:foo) do |item|
  #        item.desc = "Test item"
  #        item.process { puts "bar" }
  #      end
  #    end
  module CollectionInterface
    attr_reader :table

    def self.included(sub)
      sub.instance_variable_set(:@__item_class__, @__item_class__)
      sub.instance_eval do
        @__item_class

        def set_item_class(klass)
          @__item_class__ = klass
        end

        def self.item_class
          @__item_class__ || (raise NotImplemented)
        end
      end

      def sub.extended(_sub)
        _sub.instance_variable_set(:@__item_class__, @__item_class__)
        _sub.instance_variable_set(:@table, Hash.new)
      end

      def sub.inherited(_sub)
        super
        _sub.instance_variable_set(:@__item_class__, @__item_class__)
      end
    end

    # Define a item in the collection. If `name` is a symbol, new item is
    # defined. If `name` is item object, use it.
    #
    # @param item [Symbol]
    #   item or item name
    # @yieldparam item [Item]
    #   a new item
    # @return [Item]
    #   the defined item
    def define(item, &block)
      # setup the item
      case item
      when Symbol
        _item = item_class.new
        _item.name = item
      when Item
        _item = item.copy
      else
        raise ArgumentError.new(item)
      end

      if block_given?
        block.call(_item)
      end

      # push it to item table
      if table.has_key?(_item.name)
        raise ArgumentError.new(_item.name)
      else
        table[_item.name] = _item
      end

      # define a getter method if this is a module
      if self.kind_of?(Module)
        singleton_class.send(:define_method, _item.name) {_item}
      end

      return _item
    end

    def find_item(name)
      table[name]
    end

    private

    # Return the item class.
    def item_class
      if klass = (@__item_class__ || self.class.instance_variable_get(:@__item_class__))
        klass
      else
        raise CollectionError.new("Item class not found for %s." % self)
      end
    end
  end

  # `Sequence` is a series of items.
  class Sequence < StructX
    include CollectionInterface

    class << self
      # Set a process context. This context is used as default context for
      # items.
      #
      # @param process_context_class [Class]
      #   process context
      # @return [void]
      def set_process_context_class(klass)
        @process_context_class = klass
      end
    end

    member :name
    member :list, :default => lambda {Array.new}
    member :table, :default => lambda {Hash.new}
    member :config, :default => lambda {Hash.new}
    member :validators, :default => lambda {Array.new}
    member :process_context_class
    member :pres, :default => lambda {Array.new}
    member :posts, :default => lambda {Array.new}
    member :exception_handlers, :default => lambda {Array.new}

    # Copy the object. This is shallow copy, but arrays are cloned.
    #
    # @return [Item]
    #   copied object
    def copy
      self.class.new.tap do |obj|
        self.each_pair do |key, val|
          obj.set(key => (val.is_a?(Array) or val.is_a?(Hash)) ? val.clone : val)
        end
      end
    end

    # Clear list.
    def clear
      list.clear
    end

    # Return the context class. If this object has no context class, return
    # class's context.
    def get_process_context_class(scenario)
      self.process_context_class || self.class.instance_variable_get(:@process_context_class) || scenario.process_context_class
    end

    # Append the item.
    #
    # @param item [Item]
    #   the action item
    # @return [void]
    def append(item)
      list.push(item)
    end
    alias :<< :append

    # Preppend the item.
    #
    # @param item [Item]
    #   the action item
    # @return [void]
    def preppend(item)
      list.unshift(item)
    end

    # Configure the sequence option.
    #
    # @param option [Hash]
    #   options
    # @return [void]
    def configure(option)
      config.merge(option)
    end

    # Define a pre-action item.
    #
    # @param name [Symbol]
    #   item name
    # @yieldparam item [Item]
    #   defined preprocess item
    def pre(name, &block)
      self.pres << item_class.new.tap do |item|
        item.name = name
        block.call(item)
      end
    end

    # Define a post-action item.
    #
    # @param name [Symbol]
    #   item name
    # @yieldparam item [Item]
    #   defined postprocess item
    def post(name, &block)
      self.posts << item_class.new.tap do |item|
        item.name = name
        block.call(item)
      end
    end

    # Define an exception handler.
    #
    # @param exceptions [Array<Class>]
    #   exception classes that handler should handle, that is assumed `StandardError` if empty
    # @yieldparam e [Exception]
    #   raised exception object
    # @yieldparam args [Array]
    #   arbitrary objects
    def exception(*exceptions, &block)
      if exceptions.empty?
        exceptions = [StandardError]
      end
      self.exception_handlers << ExceptionHandler.new(exceptions, block)
    end

    # Use the item. This defines an item and pushs it to the sequence.
    #
    # @param item [Symbol or Item]
    #   item
    # @yield [item]
    #   the cloned item
    def use(item, &block)
      _item = define(item, &block)
      list << _item
    end

    def execute(scenario, &block)
      catch(:rootage_sequence_quit) do
        execute_pre(scenario, &block)
        execute_main(scenario, &block)
        execute_post(scenario, &block)
      end
    rescue Exception => e
      catch(:rootage_item_stop) do
        if exception_handlers.find do |handler|
            catch(:rootage_process_failure) do
              handler.try_to_handle(get_process_context_class(scenario).new(scenario), e, args)
            end
          end
        else
          raise
        end
      end
    end

    private

    def execute_pre(scenario, &block)
      execute_items(pres, scenario, &block)
    end

    def execute_main(scenario, &block)
      execute_items(list, scenario, &block)
    end

    def execute_post(scenario, &block)
      execute_items(posts, scenario, &block)
    end

    # Execute all actions in this sequence.
    #
    # @param cmd [Scenario]
    #   a scenario owned this sequence
    # @return [void]
    def execute_items(items, scenario, &block)
      items.each {|item| execute_item(scenario, item, &block)}
    end

    def execute_item(scenario, item, &block)
      if item.is_a?(Symbol)
        if table.has_key?(item)
          item = table[item]
        else
          raise NoSuchItem.new(scenario.name, name, item)
        end
      end

      # set context class
      if item.process_context_class.nil?
        item.process_context_class = get_process_context_class(scenario)
      end

      if block_given?
        yield item
      end

      item.execute(scenario)

      # log
      args = {scenario: scenario.name, phase: name, action: item.name}
      Log.debug('"%{scenario}" has executed an item "%{action}" at the phase "%{phase}".' % args)
    end
  end

  # `ProcessContext` is a context for processes. Each process is evaluated in
  # this context object.
  class ProcessContext
    # Make a subclass.
    def self.make(&block)
      klass = Class.new(self)
      klass.instance_exec(&block)
      return klass
    end

    attr_reader :scenario
    attr_reader :model

    # @param scenario [Scenario]
    #   a scenario that owns this process
    def initialize(scenario)
      @scenario = scenario
      @model = scenario.model
    end

    # Test the value. If it is false or nil, the action firing
    # ends. Otherwise, return itself.
    def test(val)
      val ? val : fail
    end

    # Fail the process.
    def fail
      throw :rootage_process_failure, false
    end
  end

  # `ExceptionHandler` is a handler of exception for action item.
  class ExceptionHandler
    def initialize(exceptions, block)
      @exceptions = exceptions
      @block = block
    end

    def try_to_handle(context, e, *args)
      if @exceptions.any?{|ec| e.kind_of?(ec)}
        handle(context, e, *args)
        return true
      end

      return false
    end

    def handle(context, e, *args)
      context.instance_exec(e, *args, &@block)
    end
  end

  # `Model` is a container for option keys and values. This is a
  # just hash table, but you can check the value is specified by user or not.
  class Model
    def initialize
      @__specified__ = Hash.new
    end

    def [](name)
      instance_variable_get("@%s" % name)
    end

    def []=(name, val)
      instance_variable_set("@%s" % name, val)
    end

    # Specify the option by user.
    #
    # @param name [Symbol]
    #   option key name
    # @param value [Object]
    #   option value
    # @return [void]
    def specify(name, value)
      self[name] = value
      @__specified__[name] = true
    end

    # Return true if the option is specified by user.
    #
    # @param name [Symbol]
    #   option key name
    # @return [Boolean]
    #   true if the option is specified by user
    def specified?(name)
      !!@__specified__[name]
    end

    # Convert the model into a hash.
    #
    # @return [Hash]
    #   a hash
    def to_hash
      instance_variables.each_with_object(Hash.new) do |var, h|
        var = var[1..-1]
        unless var.to_s.start_with?("__")
          h[var] = self[var]
        end
      end
    end
  end
end
