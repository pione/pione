module Pione
  module Lang
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
    class PioneMethod < StructX
      member :method_type
      member :name
      member :inputs
      member :output
      member :body

      # Call the method with recevier and arguemnts.
      def call(env, receiver, args)
        _output = receiver.pione_type(env).instance_exec(env, receiver, *args, &body)
        if _output.nil?
          p self
          p receiver
          p args
        end
        validate_output(env, receiver, _output)
        return _output
      end

      # Validate inputs data types for the method.
      #
      # @param receiver_type [Type]
      #   receiver type
      # @param args [Array<Object>]
      #   arguments
      # @return [Boolean]
      #   true if input data are valid
      def validate_inputs(env, rec, args)
        # check size
        return false unless inputs.size == args.size

        # check type
        inputs.each_with_index do |input, i|
          input = get_type(env, input, rec)
          unless input.match(env, args[i])
            return false
          end
        end
        return true
      end

      # Validate output data type for the method.
      def validate_output(env, receiver, value)
        _output = get_type(env, output, receiver)
        unless _output.match(env, value)
          raise MethodInterfaceError.new(:output, name, [_output], [value])
        end
      end

      # Get the input types of receiver.
      def get_input_types(env, receiver)
        inputs.map{|input| get_type(env, input, receiver)}
      end

      # Get the output type of receiver.
      def get_output_type(env, receiver)
        get_type(env, output, receiver)
      end

      private

      # Get a type object.
      def get_type(env, type, receiver)
        case type
        when :index_type
          receiver.index_type(env)
        when :element_type
          receiver.element_type(env)
        when :receiver_type
          receiver.pione_type(env)
        else
          type
        end
      end
    end
  end
end
