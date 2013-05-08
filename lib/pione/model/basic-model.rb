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
          @type.type_string,
          @obj.pione_model_type.type_string,
          @obj.line,
          @obj.column
        ]
        "expected %s, but got %s(line: %s, column: %s)" % args
      end
    end

    # MethodNotFound is an exception class for the case of method missing.
    class MethodNotFound < StandardError
      attr_reader :name
      attr_reader :obj

      # Creates an exception.
      # @param [String, Symbol] name
      #   method name
      # @param [BasicModel] obj
      #   method reciever
      def initialize(name, obj)
        @name = name
        @obj = obj
      end

      # @api private
      def message
        str = nil
        begin
          str = @obj.call_pione_method("as_string")
        rescue => e
          str = @obj.to_s
        end
        "method \"%s\" is not found in %s" % [@name, str]
      end
    end

    # Type is a class for type expression of PIONE model objects.
    class Type < System::PioneObject
      attr_reader :type_string
      attr_reader :method_interface
      attr_reader :method_body

      # Creates a type for PIONE model object.
      # @param [Symbol] type_string
      #   PIONE model type
      def initialize(type_string)
        @type_string = type_string
        @method_interface = {}
        @method_body = {}
      end

      # Return true if the type or the pione model object matches.
      # @param [Type, BasicModel] other
      #   type or object for match test target
      # @return [Boolean]
      #   true if it matches, or false
      def match(other)
        case other
        when Type
          other == TypeAny || @type_string == other.type_string
        when BasicModel
          match(other.pione_model_type)
        when nil
          # do nothing
        else
          raise ArgumentError.new(other)
        end
      end

      # Defines PIONE model object methods.
      # @param [String] name
      #   method name
      # @param [Array<Type>] inputs
      #   input types of the method
      # @param [Type] output
      #   output type of the method
      # @param [Proc] b
      # @return [void]
      def define_pione_method(name, inputs, output, &b)
        raise ArgumentError.new(inputs) unless inputs.kind_of?(Array)
        raise ArgumentError.new(inputs) unless inputs.all?{|input|
          input.kind_of?(Type) or input.kind_of?(Symbol)
        }
        raise ArgumentError.new(output) unless output.kind_of?(Type) or output.kind_of?(Symbol)
        @method_interface[name] = PioneMethodInterface.new(inputs, output)
        @method_body[name] = b
      end

      # Returns true if the data has the type.
      # @return [void]
      def check(data)
        unless match(data.pione_model_type)
          raise PioneModelTypeError.new(data, self)
        end
      end

      def type_to_class(type)
        case type
        when TypeString
          PioneStringSequence
        when TypeInteger
          PioneIntegerSequence
        when TypeFloat
          PioneFloatSequence
        when TypeBoolean
          PioneBooleanSequence
        end
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

      def sequential_pred1(seq1, &b)
        method1 = seq1.every? ? :all? : :any?
        seq1.elements.send(method1) do |elt1|
          PioneBoolean.new(b.call(elt1))
        end.tap {|x| break PioneBooleanSequence.new(x)}
      end

      def sequential_pred2(seq1, seq2, &b)
        method1 = seq1.every? ? :all? : :any?
        method2 = seq2.every? ? :all? : :any?
        seq1.elements.send(method1) do |elt1|
          seq2.elements.send(method2) do |elt2|
            b.call(elt1, elt2)
          end
        end.tap {|x| break PioneBooleanSequence.new([PioneBoolean.new(x)])}
      end

      # @api private
      def to_s
        "#<Type %s>" % @type_string
      end
    end

    class VariableType
      def initialize(name)
        @name = name
      end
    end

    # TypeList represetnts list type of element type.
    class TypeList < Type
      attr_reader :element_type

      # @api private
      @table = {}

      class << self
        def [](type)
          if @table.has_key?(type)
            return @table[type]
          else
            t = new(type)
            @table[type] = t
            return t
          end
        end
      end

      def initialize(element_type)
        @element_type = element_type
        super("[%s]" % [element_type.type_string])
      end

      def match(other)
        return false unless other.kind_of?(TypeList)
        @element_type.match(other.element_type)
      end

      def method_body
        if self == self.class[TypeAny]
          @method_body
        else
          self.class[TypeAny].method_body
        end
      end

      def method_interface
        if self == self.class[TypeAny]
          @method_interface
        else
          self.class[TypeAny].method_interface
        end
      end
    end

    # PioneMethodInterface represents type of PIONE object's methods.
    class PioneMethodInterface < Pione::PioneObject
      attr_reader :inputs
      attr_reader :output

      # Creates an interface for a pione method.
      # @param [Array<Type>] inputs
      #   inputs type definition
      # @param [Type] output
      #   ouutput type definition
      def initialize(inputs, output)
        @inputs = inputs
        @output = output
      end

      # Validate inputs data types for the method.
      #
      # @param receiver_type [Type]
      #   receiver type
      # @param args [Array<Object>]
      #   arguments
      # @return [void]
      def validate_inputs(receiver_type, *args)
        @inputs.each_with_index do |input, i|
          input = receiver_type if input == :receiver_type
          unless input.match(args[i].pione_model_type)
            raise PioneModelTypeError.new(args[i], input)
          end
        end
      end

      # Validate output data type for the method.
      #
      # @param receiver_type [Type]
      #   recevier type
      # @param value [Object]
      #   output value
      # @return [void]
      def validate_output(receiver_type, value)
        output = @output == :receiver_type ? receiver_type : @output
        output.match(value.pione_model_type)
      end
    end

    # boolean type for PIONE system
    TypeBoolean = Type.new("boolean")

    # integer type for PIONE system
    TypeInteger = Type.new("integer")

    # float type for PIONE system
    TypeFloat = Type.new("float")

    # string type for PIONE system
    TypeString = Type.new("string")

    # data expression type for PIONE system
    TypeDataExpr = Type.new("data-expr")

    # feature type for PIONE system
    TypeFeature = Type.new("feature")

    # rule expression type for PIONE system
    TypeRuleExpr = Type.new("rule-expr")

    # parameters type for PIONE system
    TypeParameters = Type.new("parameters")

    # assignment type for PIONE system
    TypeAssignment = Type.new("assignment")

    # variable table type for PIONE system
    TypeVariableTable = Type.new("variable-table")

    # package type for PIONE system
    TypePackage = Type.new("package")

    # undefined value type for PIONE system
    TypeUndefinedValue = Type.new("undefined-value")

    # rule io list type for PIONE system
    TypeRuleIOList = Type.new("rule-io-list")

    # rule io element type for PIONE system
    TypeRuleIOElement = Type.new("rule-io-element")

    # ticket expression type
    TypeTicketExpr = Type.new("ticket-expr")

    # any type for PIONE system
    TypeAny = Type.new("any")

    def TypeAny.match(other)
      true
    end

    TypeAny.instance_eval do
      define_pione_method("==", [:receiver_type], TypeBoolean) do |rec, other|
        if rec.elements.size == other.elements.size
          rec.elements.size.times.all? do |i|
            rec.elements[i].value == other.elements[i].value
          end.tap {|x| break PioneBooleanSequence.new([PioneBoolean.new(x)], rec.attribute)}
        else
          PioneBooleanSequence.new([PioneBoolean.new(false)], rec.attribute)
        end
      end

      define_pione_method("!=", [:receiver_type], TypeBoolean) do |rec, other|
        rec.call_pione_method("==", other).call_pione_method("not")
      end

      define_pione_method("===", [:receiver_type], TypeBoolean) do |rec, other|
        sequential_pred2(rec, other) do |rec_elt, other_elt|
          rec_elt.value == other_elt.value
        end
      end

      define_pione_method("!==", [:receiver_type], TypeBoolean) do |rec, other|
        rec.call_pione_method("===", other).call_pione_method("not")
      end

      define_pione_method("|", [:receiver_type], :receiver_type) do |rec, other|
        rec.concat(other)
      end

      define_pione_method("each", [], :receiver_type) do |rec|
        rec.each
      end

      define_pione_method("each?", [], TypeBoolean) do |rec|
        PioneBooleanSequence.new([PioneBoolean.new(rec.each?)])
      end

      define_pione_method("all", [], :receiver_type) do |rec|
        rec.all
      end

      define_pione_method("all?", [], TypeBoolean) do |rec|
        PioneBooleanSequence.new([PioneBoolean.new(rec.all?)])
      end

      define_pione_method("every", [], :receiver_type) do |rec|
        rec.every
      end

      define_pione_method("every?", [], TypeBoolean) do |rec|
        PioneBooleanSequence.new([PioneBoolean.new(rec.every?)])
      end

      define_pione_method("any", [], :receiver_type) do |rec|
        rec.any
      end

      define_pione_method("any?", [], TypeBoolean) do |rec|
        PioneBooleanSequence.new([PioneBoolean.new(rec.any?)])
      end

      define_pione_method("i", [], TypeInteger) do |rec|
        rec.call_pione_method("as_integer")
      end

      define_pione_method("f", [], TypeFloat) do |rec|
        rec.call_pione_method("as_float")
      end

      define_pione_method("str", [], TypeString) do |rec|
        rec.call_pione_method("as_string")
      end

      define_pione_method("d", [], TypeDataExpr) do |rec|
        rec.call_pione_method("as_data_expr")
      end

      define_pione_method("length", [], TypeInteger) do |rec|
        PioneIntegerSequence.new([PioneInteger.new(rec.elements.size)])
      end

      define_pione_method("[]", [TypeInteger], :receiver_type) do |rec, index|
        receiver_class = rec.class
        receiver_element_class = rec.class.element_class
        index.elements.map do |i|
          if i.value == 0
            receiver_element_class.new(rec.value)
          else
            rec.elements[i.value-1]
          end
        end.tap {|x| break receiver_class.new(x, rec.attribute)}
      end

      define_pione_method("type", [], TypeString) do |rec|
        case rec
        when PioneStringSequence
          "string"
        when PioneIntegerSequence
          "integer"
        when PioneFloatSequence
          "float"
        when PioneBooleanSequence
          "boolean"
        else
          "undefined"
        end.tap {|x| break PioneString.new(x).to_seq}
      end
    end

    # BasicModel is a class for pione model object.
    class BasicModel < Pione::PioneObject
      class << self
        # Sets pione model type of the model.
        # @param [Symbol] type
        #   pione model type
        # @return [void]
        def set_pione_model_type(type)
          raise ArgumentError unless type.kind_of?(Type)
          @pione_model_type = type
        end

        # Returns the pione model type of the model.
        # @return [Symbol]
        #   pione model type
        def pione_model_type
          @pione_model_type
        end

        # Defines a pione method.
        # @return [void]
        def define_pione_method(*args, &b)
          @pione_model_type.define_pione_method(*args, &b)
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

      # Evaluates the model object in the variable table.
      # @param [VariableTable] vtable
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluated object
      def eval(vtable=VariableTable.new)
        return self
      end

      # Returns true if the object is atomic.
      # @return [Boolean]
      #   true if the object is atom, or false.
      def atomic?
        true
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

      def method_interface(name)
        if interface = pione_model_type.method_interface[name]
          body = pione_model_type.method_body[name]
          return interface, body
        else
          interface = TypeAny.method_interface[name]
          body = TypeAny.method_body[name]
          return interface, body
        end
      end

      # Calls pione model object method.
      # @param [String] name
      #   method name
      # @param [Array] args
      #   method's arguments
      # @return [Object]
      #   method's result
      def call_pione_method(name, *args)
        name = name.to_s
        interface, body = method_interface(name)
        if interface and body
          interface.validate_inputs(pione_model_type, *args)
          output = body.call(self, *args)
          interface.validate_output(pione_model_type, output)
          return output
        else
          raise MethodNotFound.new(name, self)
        end
      end

      # Returns itself.
      # @return [BasicModel]
      def to_pione
        self
      end
    end

    class SequenceAttributeError < StandardError
      def initialize(attribute)
        @attribute = attribute
      end

      def message
        "attribute mismatched: %s" % @attribute
      end
    end

    class BasicSequence < BasicModel
      include Enumerable

      class << self
        def define_attribute(name, value)
          define_method(value) do
            self.class.new(@elements, @attribute.merge({name => value}))
          end

          define_method("%s?" % value) do
            @attribute[name] == value
          end
        end

        attr_reader :element_class

        def set_element_class(klass)
          @element_class = klass
        end
      end

      attr_reader :elements
      attr_reader :attribute

      define_attribute(:modifier, :all)
      define_attribute(:modifier, :each)
      define_attribute(:enumeration, :any)
      define_attribute(:enumeration, :every)

      def initialize(elements, attribute={})
        @elements = elements
        @attribute = Hash.new.merge(attribute)
        @attribute[:modifier] ||= :each
        @attribute[:enumeration] ||= :any
      end

      def concat(other)
        raise SequenceAttributeError.new(other) unless @attribute == other.attribute
        self.class.new(@elements + other.elements, @attribute)
      end

      def each
        if block_given?
          @elements.each {|e| yield self.class.new([e], @attribute)}
        else
          Enumerator.new(self, :each)
        end
      end

      def eval(vtable)
        self.class.new(@elements.map{|elt| elt.eval(vtable)}, @attribute)
      end

      def include_variable?
        @elements.any?{|elt| elt.include_variable?}
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless @elements == other.elements
        return @attribute == other.attribute
      end
      alias :eql? :"=="

      def hash
        @elements.hash + @attribute.hash
      end

      def task_id_string
        "<#{@elements}, #{@attribute}>"
      end

      def textize
        "<%s [%s]>" % [shortname, @elements.map{|x| x.textize}.join(",")]
      end

      def inspect
        "#<%s %s %s>" % [shortname, @elements, @attribute]
      end

      private

      def shortname
        case self.class
        when PioneStringSequence; "StrSeq"
        when PioneIntegerSequence; "ISeq"
        when PioneFloatSequence; "FSeq"
        when PioneBooleanSequence; "BSeq"
        end
      end
    end
  end
end
