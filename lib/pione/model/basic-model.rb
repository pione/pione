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
          @obj.pione_type.name,
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
      def initialize(name, receiver, arguments)
        @name = name
        @receiver = receiver
        @arguments = arguments
      end

      def message
        rec_type = @receiver.pione_type
        arg_types = @arguments.map{|arg| arg.pione_type}.join(" -> ")
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
      def eval(env)
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
    end
  end
end
