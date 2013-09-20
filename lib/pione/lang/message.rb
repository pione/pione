module Pione
  module Lang
    # Message represents method callers in PIONE language.
    class Message < Expr
      member :name
      member :receiver
      member :arguments

      # Return PIONE model type of the message result according to type interface.
      def pione_type(env)
        if pione_method = receiver.pione_type.find_method(env, name, receiver, arguments)
          pione_method.get_output_type(receiver)
        else
          raise MethodNotFound.new(name.to_s, receiver, arguments)
        end
      end

      # Evaluate the application expression and returns application result.
      def eval(env)
        # evaluate the receiver in the environment
        _receiver = receiver.eval(env)
        if _receiver.is_a?(Variable)
          _receiver = _receiver.eval(env)
        end

        # send a message to it
        _receiver.call_pione_method(env, name, arguments)
      end

      def eval!(env)
        eval(env).eval!(env)
      end

      # Convert to text string.
      def textize
        args = arguments.map {|arg| arg.textize}
        "#%s{name: %s, receiver: %s, arguments: %s}" % [Message, name, receiver.textize, args]
      end
    end
  end
end
