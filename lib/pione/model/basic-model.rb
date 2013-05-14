module Pione
  module Model
    # PioneModelTypeError represents type mismatch error in PIONE modle object system.
    class PioneModelTypeError < StandardError
      # Creates an exception.
      # @param [BasicModel] obj PIONE model object
      # @param [Type] type expected type
      def initialize(obj, type)
        @obj = obj
        @type = type
      end

      # @api private
      def message
        args = [
          @type.name,
          @obj.pione_model_type.name,
          @obj.line,
          @obj.column
        ]
        "expected %s, but got %s(line: %s, column: %s)" % args
      end
    end

    # MethodNotFound is an exception class for the case of method missing.
    class MethodNotFound < StandardError
      attr_reader :name
      attr_reader :receiver
      attr_reader :arguments

      # Creates an exception.
      # @param name [String]
      #   method name
      # @param receiver [Callable]
      #   method reciever
      # @param arguments [Array<Callable>]
      #   method arguments
      def initialize(name, receiver, *arguments)
        @name = name
        @receiver = receiver
        @arguments = arguments
      end

      def message
        rec_type = @receiver.pione_model_type
        arg_types = @arguments.map{|arg| arg.pione_model_type}.join(" -> ")
        "PIONE method \"%s\" is not found: %s. %s" % [@name, rec_type, arg_types]
      end
    end

    # BasicModel is a class for pione model object.
    class BasicModel < Pione::PioneObject
      class << self
        # Return true if the object is atomic.
        #
        # @return [Boolean]
        #   true if the object is atom, or false.
        def atomic?
          @atomic ||= true
        end

        def set_atomic(b)
          @atomic = b
        end
      end

      forward :class, :atomic?

      # Creates a model object.
      def initialize(&b)
        instance_eval(&b) if block_given?
      end

      # Evaluates the model object in the variable table.
      # @param [VariableTable] vtable
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluated object
      def eval(vtable=VariableTable.new)
        return self
      end

      # Returns true if the object has pione variables.
      # @return [Boolean]
      #   true if the object has pione variables, or false
      def include_variable?
        false
      end

      # Returns rule definition document path.
      # @return [void]
      def set_document_path(path)
        @__document_path__ = path
      end

      # Sets line and column number of the definition.
      # @return [void]
      def set_line_and_column(line_and_column)
        @__line__, @__column__ = line_and_column
      end

      # Returns line number of the model in definition document.
      # @return [Integer]
      #   line number
      def line
        @__line__
      end

      # Returns coloumn number of the model in definition document.
      # @return [Integer]
      #   column number
      def column
        @__column__
      end

      # Returns itself.
      # @return [BasicModel]
      def to_pione
        self
      end
    end

    class Callable < BasicModel
      class << self
        attr_reader :pione_model_type

        # Set pione model type of the model.
        #
        # @param [Type] type
        #   pione model type
        # @return [void]
        def set_pione_model_type(type)
          @pione_model_type = type
        end

        # @api private
        def inherited(subclass)
          if @pione_model_type
            subclass.set_pione_model_type @pione_model_type
          end
        end
      end

      forward :class, :pione_model_type

      # Creates a model object.
      def initialize(&b)
        instance_eval(&b) if block_given?
      end

      # Evaluate the model object in the variable table.
      #
      # @param [VariableTable] vtable
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluated result
      def eval(vtable=VariableTable.new)
        return self
      end

      # Returns true if the object has pione variables.
      # @return [Boolean]
      #   true if the object has pione variables, or false
      def include_variable?
        false
      end

      # Call pione model object method.
      #
      # @param [String] name
      #   method name
      # @param [Array] args
      #   method's arguments
      # @return [Object]
      #   method's result
      def call_pione_method(name, *args)
        if pione_method = pione_model_type.find_method(name, self, *args)
          pione_method.call(self, *args)
        else
          raise MethodNotFound.new(name, self, *args)
        end
      end

      # Returns itself.
      # @return [BasicModel]
      def to_pione
        self
      end
    end

    class Element < BasicModel
      class << self
        attr_reader :sequence_class

        def set_sequence_class(sequence_class)
          @sequence_class = sequence_class
        end
      end

      forward :class, :sequence_class

      def to_seq
        sequence_class.new([self])
      end
    end

    class Value < Element
      attr_reader :value

      # @param value [Object]
      #   value in ruby
      def initialize(value)
        @value = value
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        @value == other.value
      end
      alias :eql? :"=="

      def hash
        @value.hash
      end

      def inspect
        '#<%s "%s">' % [self.class.name, @value]
      end
      alias :to_s :inspect
    end
  end
end
