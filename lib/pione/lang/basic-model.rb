module Pione
  module Lang
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
