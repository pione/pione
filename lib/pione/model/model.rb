module Pione::Model

  # PioneModelTypeError represents type mismatch error in PIONE modle object system.
  class PioneModelTypeError < StandardError
    # Creates an exception.
    # @param [PioneModelObject] obj PIONE model object
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
    # @param [PioneModelObject] obj
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
  class Type < Pione::PioneObject
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
    # @param [Type, PioneModelObject] other
    #   type or object for match test target
    # @return [Boolean]
    #   true if it matches, or false
    def match(other)
      case other
      when Type
        other == TypeAny || @type_string == other.type_string
      when PioneModelObject
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
        input.kind_of?(Type)
      }
      raise ArgumentError.new(output) unless output.kind_of?(Type)
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

    # @api private
    def to_s
      "#<Type %s>" % @type_string
    end

    # @api private
    def ==(other)
      @type_string == other.type_string
    end

    # @api private
    def hash
      @type_string.hash
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

    # Validates inputs data types for the method.
    # @return [void]
    def validate_inputs(*args)
      @inputs.each_with_index do |input, i|
        unless input.match(args[i].pione_model_type)
          raise PioneModelTypeError.new(args[i], input)
        end
      end
    end

    # Validates output data type for the method.
    # @return [void]
    def validate_output(value)
      @output.match(value.pione_model_type)
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

  # any type for PIONE system
  TypeAny = Type.new("any")

  def TypeAny.match(other)
    true
  end

  TypeAny.instance_eval do
    define_pione_method("==", [TypeAny], TypeBoolean) do |res, other|
      if other.pione_model_type == TypeAny && res.name == other.name
        PioneBoolean.true
      else
        raise UnboundVariableError.new(res)
      end
    end

    define_pione_method("!=", [TypeAny], TypeBoolean) do |res, other|
      PioneBoolean.not(res.call_pione_method("==", other))
    end
  end

  # This is a class for pione model object.
  class PioneModelObject < Pione::PioneObject
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

    # Creates a model object.
    def initialize(&b)
      instance_eval(&b) if block_given?
    end

    # Returns PIONE model type.
    # @return [Symbol]
    #   PIONE model type
    def pione_model_type
      self.class.pione_model_type
    end

    # Evaluates the model object in the variable table.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [PioneModelObject]
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

    # Calls pione model object method.
    # @param [String] name
    #   method name
    # @param [Array] args
    #   method's arguments
    # @return [Object]
    #   method's result
    def call_pione_method(name, *args)
      name = name.to_s
      if method = pione_model_type.method_interface[name]
        method.validate_inputs(*args)
        output = pione_model_type.method_body[name].call(self, *args)
        pione_model_type.method_interface[name].validate_output(output)
        return output
      else
        raise MethodNotFound.new(name, self)
      end
    end

    # Returns itself.
    # @return [PioneModelObject]
    def to_pione
      self
    end
  end

  require 'pione/model/undefined-value'
  require 'pione/model/list'
  require 'pione/model/boolean'
  require 'pione/model/integer'
  require 'pione/model/float'
  require 'pione/model/string'
  require 'pione/model/feature-expr'
  require 'pione/model/variable'
  require 'pione/model/variable-table'
  require 'pione/model/data-expr'
  require 'pione/model/parameters'
  require 'pione/model/package'
  require 'pione/model/rule-expr'
  require 'pione/model/binary-operator'
  require 'pione/model/message'
  require 'pione/model/call-rule'
  require 'pione/model/assignment'
  require 'pione/model/block'
  require 'pione/model/rule'
  require 'pione/model/rule-io'
end
