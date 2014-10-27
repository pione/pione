module Pione
  module Lang
    # Expr is a base class for all PIONE expressions.
    class Expr < StructX
      include Util::Positionable
      immutable true

      class << self
        # Set pione model type of the model.
        def pione_type(env=nil)
          @pione_type
        end

        def set_pione_type(type)
          @pione_type = type
          Type.table[type.name][:sequence_class] = self
        end

        def inherited(subclass)
          if @pione_type
            subclass.set_pione_type(@pione_type)
          end
        end
      end

      forward :class, :pione_type

      def eval(env)
        return self
      end

      def eval!(env)
        return self
      end

      # Convert to text string.
      def textize
        args = to_h.map do |key, val|
          "%s: %s" % [key, val.kind_of?(Piece) ? val.textize : val.to_s]
        end.join(", ")
        "#%s{%s}" % [piece_classes.first.piece_type_name, args]
      end

      def to_s
        textize
      end
    end

    module Callable
      # Call the pione method.
      def call_pione_method(env, name, args)
        # check arguments
        raise ArgumentError.new(args) unless args.is_a?(Array)

        if pione_method = pione_type(env).find_method(env, name, self, args)
          # evaluate arguments if the method type is immediate
          if pione_method.method_type == :immediate
            args = args.map {|arg| arg.eval(env)}
          end
          # call it
          pione_method.call(env, self, args)
        else
          raise MethodNotFound.new(env, name, self, args)
        end
      end
    end
  end
end
