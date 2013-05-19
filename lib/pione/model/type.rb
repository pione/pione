module Pione
  module Model
    # Type is a class for type expression of PIONE model objects.
    class Type < System::PioneObject
      @table = Hamster.hash

      class << self
        def put(name, value)
          @table = @table.put(name, value)
        end

        def get(name)
          @table.get(name)
        end
      end

      attr_reader :name
      attr_reader :parent_type
      attr_reader :pione_method

      # Create a type for PIONE model object.
      #
      # @param name [Symbol]
      #   type name
      # @param parent_type [Type]
      #   parent type
      def initialize(name, parent_type=nil)
        @name = name
        @parent_type = parent_type
        @pione_method = Hamster.hash
        Type.put(name, self)
      end

      # Return true if the type or the pione model object matches.
      #
      # @param [BasicModel] target
      #   matching test target
      # @return [Boolean]
      #   true if it matches, or false
      def match(target)
        target_type = target.pione_model_type
        while target_type do
          return true if self == target_type
          target_type = target_type.parent_type
        end
        return false
      end

      # Find named method.
      #
      # @param name [String]
      #   method name
      # @param rec [Callable]
      #   receiver
      # @param args [Array<BasicModel>]
      #   arguments
      # @return [void]
      def find_method(name, rec, *args)
        name = name.to_s
        if @pione_method.has_key?(name)
          @pione_method[name].each do |pione_method|
            if pione_method.validate_inputs(rec, *args)
              return pione_method
            end
          end
        else
          return @parent_type ? @parent_type.find_method(name, rec, *args) : nil
        end
      end

      # Define PIONE model object methods.
      #
      # @param name [Symbol]
      #   method name
      # @param inputs [Array<Type>]
      #   input types of the method
      # @param output [Type]
      #   output type of the method
      # @param [Proc] b
      # @return [void]
      def define_pione_method(name, inputs, output, &b)
        name = name.to_s
        method = PioneMethod.new(name, inputs, output, b)
        list = @pione_method.fetch(name, Hamster.list)
        @pione_method = @pione_method.put(name, list.cons(method))
      end

      # Return true if the data has the type.
      #
      # @return [void]
      def check(data)
        unless match(data)
          raise PioneModelTypeError.new(data, self)
        end
      end

      def type_to_class(type)
        case type
        when TypeString
          StringSequence
        when TypeInteger
          IntegerSequence
        when TypeFloat
          FloatSequence
        when TypeBoolean
          BooleanSequence
        when TypeDataExpr
          DataExprSequence
        when TypeTicketExpr
          TicketExprSequence
        end
      end

      def map1(seq, &b)
        seq_class = type_to_class(self)
        seq_class.new(seq.elements.map{|elt| b.call(elt)}, seq.attribute)
      end

      def map2(seq1, seq2, &b)
        seq_class = type_to_class(self)
        seq1.elements.map do |elt1|
          seq2.elements.map do |elt2|
            b.call(elt1, elt2)
          end
        end.flatten.tap {|x| break seq_class.new(x, seq1.attribute)}
      end

      def sequential_map1(type, seq1, &b)
        seq_class = type_to_class(type)
        seq1.elements.map do |elt1|
          seq_class.element_class.new(b.call(elt1))
        end.tap {|x| break seq_class.new(x, seq1.attribute)}
      end

      def sequential_map2(type, seq1, seq2, &b)
        seq_class = type_to_class(type)
        seq1.elements.map do |elt1|
          seq2.elements.map do |elt2|
            seq_class.element_class.new(b.call(elt1, elt2))
          end
        end.flatten.tap {|x| break seq_class.new(x, seq1.attribute)}
      end

      def sequential_map3(type, seq1, seq2, seq3, &b)
        seq_class = type_to_class(type)
        seq1.elements.map do |elt1|
          seq2.elements.map do |elt2|
            seq3.elements.map do |elt3|
              seq_class.element_class.new(b.call(elt1, elt2, elt3))
            end
          end
        end.flatten.tap {|x| break seq_class.new(x, seq1.attribute)}
      end

      def fold1(val, seq1, &b)
        seq1.elements.inject(val) do |obj, elt1|
          b.call(obj, elt1)
        end
      end

      def sequential_fold1(type, seq1, &b)
        seq_class = type_to_class(type)
        seq1.elements.inject(seq_class.new([], seq1.attribute)) do |obj, elt1|
          b.call(elt1, obj)
        end
      end

      def sequential_fold2(type, seq1, seq2, &b)
        seq_class = type_to_class(type)
        seq1.elements.inject(seq_class.new([], seq1.attribute)) do |obj1, elt1|
          seq2.elements.inject(obj1) do |obj2, elt2|
            b.call(obj2, elt1, elt2)
          end
        end
      end

      def sequential_pred1(seq1, &b)
        method1 = seq1.every? ? :all? : :any?
        seq1.elements.send(method1) do |elt1|
          PioneBoolean.new(b.call(elt1))
        end.tap {|x| break BooleanSequence.new(x)}
      end

      def sequential_pred2(seq1, seq2, &b)
        method1 = seq1.every? ? :all? : :any?
        method2 = seq2.every? ? :all? : :any?
        seq1.elements.send(method1) do |elt1|
          seq2.elements.send(method2) do |elt2|
            b.call(elt1, elt2)
          end
        end.tap {|x| break BooleanSequence.new([PioneBoolean.new(x)])}
      end

      def to_s
        "#<Type %s>" % @name
      end
    end

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

    # parameters type for PIONE system
    TypeParameters = Type.new("parameters", TypeOrdinalSequence)

    # assignment type for PIONE system
    TypeAssignment = Type.new("assignment", TypeOrdinalSequence)

    # variable table type for PIONE system
    TypeVariableTable = Type.new("variable-table", TypeOrdinalSequence)

    # package type for PIONE system
    TypePackageExpr = Type.new("package-expr", TypeOrdinalSequence)

    # ticket expression type
    TypeTicketExpr = Type.new("ticket-expr", TypeOrdinalSequence)

    def TypeSequence.match(other)
      true
    end
  end
end
