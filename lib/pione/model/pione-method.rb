module Pione
  module Model
    # MethodInterfaceError is a exception for method interface mismatching.
    class MethodInterfaceError < StandardError
      attr_reader :kind
      attr_reader :name
      attr_reader :types
      attr_reader :values

      # @param kind [Symbol]
      #   :input or :output
      # @param name [String]
      #   method name
      # @param types [Array<Type>]
      #   expected types
      # @param values [Array<BasicModel>]
      #   values
      def initialize(kind, name, types, values)
        @kind = kind
        @name = name
        @types = types
        @values = values
      end

      def message
        types = @types.map{|type| type}.join(" -> ")
        values = @values.map{|value| value.inspect}.join(" -> ")
        '"%s" expected %s but got %s' % [@name, types, values]
      end
    end

    # PioneMethod is a class represents method in PIONE system.
    class PioneMethod < Pione::PioneObject
      attr_reader :name
      attr_reader :inputs
      attr_reader :output
      attr_reader :body

      # @param name [String]
      #   method name
      # @param inputs [Array<Type>]
      #   input types
      # @param output [Type]
      #   ouutput types
      def initialize(name, inputs, output, body)
        @name = name
        @inputs = inputs
        @output = output
        @body = body
      end

      # Call the method with recevier and arguemnts.
      #
      # @param receiver [BasicModel]
      #   receiver object
      # @param args [Array<BasicModel>]
      #   arguments
      # @return [BasicModel]
      #   the result
      def call(receiver, *args)
        output = receiver.pione_model_type.instance_exec(receiver, *args, &@body)
        validate_output(receiver, output)
        return output
      end

      # Validate inputs data types for the method.
      #
      # @param receiver_type [Type]
      #   receiver type
      # @param args [Array<Object>]
      #   arguments
      # @return [Boolean]
      #   true if input data are valid
      def validate_inputs(receiver, *args)
        # check size
        return false unless @inputs.size == args.size

        # check type
        @inputs.each_with_index do |input, i|
          input = get_type(input, receiver)
          unless input.match(args[i])
            return false
          end
        end
        return true
      end

      # Validate output data type for the method.
      #
      # @param receiver_type [Type]
      #   recevier type
      # @param value [BasicModel]
      #   output value
      # @return [void]
      def validate_output(receiver, value)
        output = get_type(@output, receiver)
        unless output.match(value)
          raise MethodInterfaceError.new(:output, @name, [output], [value])
        end
      end

      # Get the input types of receiver.
      #
      # @param receiver [Callable]
      #   receiver
      # @return [Type]
      #   input types
      def get_input_types(receiver)
        @inputs.map{|input| get_type(input, receiver)}
      end

      # Get the output type of receiver.
      #
      # @param receiver [Callable]
      #   receiver
      # @return [Type]
      #   output type
      def get_output_type(receiver)
        get_type(@output, receiver)
      end

      private

      # Get a type object.
      #
      # @param type [Type, Symbol]
      #   type object or special type symbol
      # @param receiver [BasicModel]
      #   receiver
      # @return [Type]
      #   type
      def get_type(type, receiver)
        case type
        when :index_type
          receiver.index_type
        when :element_type
          receiver.element_type
        when :receiver_type
          receiver.pione_model_type
        else
          type
        end
      end
    end
  end
end
