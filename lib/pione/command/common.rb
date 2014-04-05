module Pione
  module Command
    class BasicItem < StructX
      # `name` is item name. This is used as a reference at controller.
      member :name

      # Attribute name in model.
      member :model_name

      # The action's description, this is shown in verbose help.
      member :desc

      # Context class, instance of this class is used as context of
      # process. This context class should inherit `ProcessContext`.
      member :context

      # Processes, this includes blocks that is definded by #define_process,
      # #define_assignment, and #define_condition
      member :processes, :default => lambda {[]}

      # Exception handlers.
      member :exception_handlers, :default => lambda {[]}

      # Define a process that is executed just after pre-process. This is used
      # for setting values excluding command model, for example global values.
      #
      # @yieldparam val [Object]
      #   arbitrary value, this is passed from #execute
      def process(&block)
        self.processes << Proc.new do |cmd, args|
          catch(:failure) do
            create_context(cmd).instance_exec(*args, &block)
          end
        end
      end

      # Define an assignment process. This assigns the result value of the block
      # to model. This is same as #action excluding model assignment.
      #
      # @param name [Symbol]
      #   attribute name in model
      # @yieldparam val [Object]
      #   normalized option value
      def assign(name=(self.model_name || self.name), &block)
        self.processes << Proc.new do |cmd, args|
          catch(:failure) do
            res = create_context(cmd).instance_exec(cmd, *args, &block)
            if name
              cmd.model[name] = res
            end
          end
        end
      end

      # Define a condition. This is a process simply, but goes to quit the whale
      # action halfway if it fails.
      #
      # @yieldparam val [Object]
      #   arbitrary value, this is passed from #execute
      def condition(&block)
        self.processes << Proc.new do |cmd, args|
          res = catch(:failure) do
            create_context(cmd).instance_exec(*args, &block)
            true
          end
          throw :quit unless res
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
      # @return [Command::BasicItem]
      #   copied object
      def copy
        self.class.new.tap do |obj|
          self.each_pair do |key, val|
            obj.set(key => val.is_a?(Array) ? val.clone : val)
          end
        end
      end

      # Execute the action.
      #
      # @param cmd [Command::PlainCommand]
      #   command
      # @param args [Array]
      #   arbitrary objects, this is passed to process's block
      # @return [void]
      def execute(cmd, *args)
        # catch "quit" message here
        catch(:quit) do
          processes.each {|block| block.call(cmd, args)}
        end
      rescue Exception => e
        exception_handlers.find do |handler|
          catch(:failure) { handler.try_to_handle(create_context(cmd), e, args) }
        end
      end

      private

      # Create a context object for processing.
      #
      # @param cmd [Command::PlainCommand]
      # @return [ProcessContext]
      #   a context object for processing
      def create_context(cmd)
        (self.context || ProcessContext).new(cmd)
      end
    end

    module CollectionInterface
      attr_reader :items

      def item_class
        raise NotImplemented
      end

      # Define a new item.
      def define(name, &b)
        item = item_class.new.tap do |item|
          item.name = name
          b.call(item)
        end

        @items ||= []
        @items << item

        # define a getter method if this is a module
        if self.kind_of?(Module)
          singleton_class.send(:define_method, name) {item}
        end
      end

      # Use the item as command option. If block is given, apply the block with
      # cloned item and use it.
      #
      # @param item [OptionItem]
      #   option item
      # @yield [item]
      #   the cloned item
      def use(item, &b)
        unless item.kind_of?(item_class)
          raise ArgumentError.new(item)
        end

        if block_given?
          _item = item.copy
          b.call(_item)
          @items << _item
        else
          @items << item
        end

        # define a getter method if this is a module
        if self.kind_of?(Module)
          singleton_class.send(:define_method, name) {item}
        end
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
  end
end
