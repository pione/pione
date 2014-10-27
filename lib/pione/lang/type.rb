module Pione
  module Lang
    # Type is a class for type expression of PIONE model objects.
    class Type < StructX
      @table = Hash.new

      class << self
        attr_reader :table
      end

      member :name
      member :parent_type
      member :pione_method, default: lambda { Hash.new }

      # Create a type for PIONE model object.
      def initialize(*args)
        super(*args)
        Type.table[name] = {parent: parent_type}
      end

      # Return true if the type or the pione model object matches.
      #
      # @param [BasicModel] target
      #   matching test target
      # @return [Boolean]
      #   true if it matches, or false
      def match(env, target)
        target_type = target.pione_type(env)
        while target_type do
          return true if self == target_type
          target_type = target_type.parent_type
        end
        return false
      end

      # Find named method.
      def find_method(env, name, rec, args)
        # find a suitable method
        if pione_method.has_key?(name)
          group = pione_method[name].group_by{|m| m.method_type}

          # exist deferred methods
          if group.has_key?(:deferred)
            if m = group[:deferred].find {|m| m.validate_inputs(rec, args)}
              return m
            end
          end

          # try immediate methods
          _args = args.map {|arg| arg.eval(env)} # FIXME : should be replaced by type inference
          return group[:immediate].find {|m| m.validate_inputs(env, rec, _args)}
        end

        # find from parent type
        if parent_type
          return parent_type.find_method(env, name, rec, args)
        end
      end

      # Define PIONE methods. Arguments are evaluated immediately.
      def define_pione_method(name, inputs, output, &b)
        (pione_method[name] ||= []) << PioneMethod.new(:immediate, name, inputs, output, b)
      end

      # Define PIONE methods. Arguments are non-evaluated.
      def define_deferred_pione_method(name, inputs, output, &b)
        (pione_method[name] ||= []) << PioneMethod.new(:deferred, name, inputs, output, b)
      end

      # Return true if the data has the type.
      #
      # @return [void]
      def check(env, data)
        unless match(env, data)
          raise LangTypeError.new(data, self, env)
        end
      end

      def sequence_class
        Type.table[self.name][:sequence_class]
      end

      def map1(seq, &b)
        sequence_class.of(seq.pieces.map{|elt| b.call(elt)}, seq.attribute)
      end

      def map2(seq1, seq2, &b)
        seq1.pieces.map do |elt1|
          seq2.pieces.map do |elt2|
            b.call(elt1, elt2)
          end
        end.flatten.tap {|x| break sequence_class.new(x, seq1.attribute)}
      end

      def sequential_map1(type, seq1, &b)
        seq_class = type_to_class(type)
        seq1.pieces.map do |elt1|
          seq_class.piece_class.new(b.call(elt1))
        end.tap {|x| break seq_class.new(x, seq1.attribute)}
      end

      def sequential_map2(type, seq1, seq2, &b)
        seq_class = type_to_class(type)
        seq1.pieces.map do |elt1|
          seq2.pieces.map do |elt2|
            seq_class.piece_class.new(b.call(elt1, elt2))
          end
        end.flatten.tap {|x| break seq1.set(x, seq1.attribute)}
      end

      def sequential_map3(type, seq1, seq2, seq3, &b)
        seq_class = type_to_class(type)
        seq1.pieces.map do |elt1|
          seq2.pieces.map do |elt2|
            seq3.pieces.map do |elt3|
              seq_class.piece_class.new(b.call(elt1, elt2, elt3))
            end
          end
        end.flatten.tap {|x| break seq_class.new(x, seq1.attribute)}
      end

      def fold1(val, seq1, &b)
        seq1.pieces.inject(val) do |obj, elt1|
          b.call(obj, elt1)
        end
      end

      def sequential_fold1(type, seq1, &b)
        seq_class = type_to_class(type)
        seq1.pieces.inject(seq_class.new([], seq1.attribute)) do |obj, elt1|
          b.call(elt1, obj)
        end
      end

      def sequential_fold2(type, seq1, seq2, &b)
        seq_class = type_to_class(type)
        seq1.pieces.inject(seq_class.new([], seq1.attribute)) do |obj1, elt1|
          seq2.pieces.inject(obj1) do |obj2, elt2|
            b.call(obj2, elt1, elt2)
          end
        end
      end

      def sequential_pred1(seq1, &b)
        method1 = seq1.every? ? :all? : :any?
        seq1.pieces.send(method1) do |elt1|
          PioneBoolean.new(b.call(elt1))
        end.tap {|x| break BooleanSequence.new(x)}
      end

      def sequential_pred2(seq1, seq2, &b)
        method1 = seq1.every? ? :all? : :any?
        method2 = seq2.every? ? :all? : :any?
        seq1.pieces.send(method1) do |elt1|
          seq2.pieces.send(method2) do |elt2|
            b.call(elt1, elt2)
          end
        end.tap {|x| break BooleanSequence.new([PioneBoolean.new(x)])}
      end

      def to_s
        "#<Type %s>" % name
      end

      def inspect
        "#<Type %s>" % name
      end
    end

    # TypeVariable is a type for variable names.
    TypeVariable = Type.new("variable")

    # TypeSequence is a type for sequence of something.
    TypeSequence = Type.new("sequence")

    # TypeOrdinalSequence is a type for integer indexed sequence.
    TypeOrdinalSequence = Type.new("ordinal-sequence", TypeSequence)

    # TypeKeyedSequence is a type for something indexed sequence.
    TypeKeyedSequence = Type.new("keyed-sequence", TypeSequence)

    # TypeBoolean is a type for integer indexed boolean sequence.
    TypeBoolean = Type.new("boolean", TypeOrdinalSequence)

    # TypeInteger is a type for integer indexed integer sequence.
    TypeInteger = Type.new("integer", TypeOrdinalSequence)

    # TypeFloat is a type for float
    TypeFloat = Type.new("float", TypeOrdinalSequence)

    # string type for PIONE system
    TypeString = Type.new("string", TypeOrdinalSequence)

    # data expression type for PIONE system
    TypeDataExpr = Type.new("data-expr", TypeOrdinalSequence)

    # feature type for PIONE system
    TypeFeature = Type.new("feature", TypeOrdinalSequence)

    # rule expression type for PIONE system
    TypeRuleExpr = Type.new("rule-expr", TypeOrdinalSequence)

    # parameter set type for PIONE system
    TypeParameterSet = Type.new("parameter-set", TypeOrdinalSequence)

    # assignment type for PIONE system
    TypeAssignment = Type.new("assignment", TypeOrdinalSequence)

    # package type for PIONE system
    TypePackageExpr = Type.new("package-expr", TypeOrdinalSequence)

    # ticket expression type
    TypeTicketExpr = Type.new("ticket-expr", TypeOrdinalSequence)

    def TypeSequence.match(env, other)
      true
    end
  end
end
