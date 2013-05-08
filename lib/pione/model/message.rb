module Pione
  module Model
    # Message represents method callers for PIONE model objects.
    #
    # @example
    #   1.as_string()
    # @example
    #   '*.txt'.except('a*')
    class Message < BasicModel
      attr_reader :name
      attr_reader :receiver
      attr_reader :arguments

      # Create a message.
      #
      # @param name [String]
      #   message name
      # @param receiver [BasicModel]
      #   message receiver
      # @param arguments [BasicModel]
      #   message arguments
      def initialize(name, receiver, *arguments)
        @name = name
        @receiver = receiver.to_pione
        @arguments = arguments.map{|arg| arg.to_pione}
        super()
      end

      # Return false because Message is a complex form.
      #
      # @return [Boolean]
      #   false
      def atomic?
        false
      end

      # Return PIONE model type of the message result according to type interface.
      #
      # @return [Symbol]
      #   PIONE model type
      def pione_model_type
        if interface = @receiver.pione_model_type.method_interface[@name.to_s]
          interface.output
        else
          raise MethodNotFound.new(@name.to_s, self)
        end
      end

      # Evaluate the application expression and returns application result.
      #
      # @param vtable [VariableTable]
      #   variable table for the evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        receiver = @receiver.eval(vtable)
        arguments = @arguments.map{|arg| arg.eval(vtable)}
        receiver.call_pione_method(@name, *arguments)
      end

      # Return true if the receiver or arguments include variables.
      #
      # @return [Boolean]
      #   true if the receiver or arguments include variables
      def include_variable?
        @receiver.include_variable? or @arguments.any?{|arg| arg.include_variable?}
      end

      # @api private
      def textize
        args = [@name, @receiver.textize, @arguments.map{|arg| arg.textize}.join(",")]
        "message(\"%s\",%s,[%s])" % args
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless @name == other.name
        return false unless @receiver == other.receiver
        return false unless @arguments == other.arguments
        return true
      end
      alias :eql? :"=="

      # @api private
      def hash
        @name.hash + @receiver.hash + @arguments.hash
      end
    end
  end
end
