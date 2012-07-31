module Pione::Model

  # PioneModelTypeError represents type mismatch error in PIONE model world.
  class PioneModelTypeError < StandardError
    # @param [PioneModelObject] obj PIONE model object
    # @param [Type] type expected type
    def initialize(obj, type)
      @obj = obj
      @type = type
    end

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

  class MethodNotFound < StandardError
    attr_reader :name
    attr_reader :obj

    def initialize(name, obj)
      @name = name
      @obj = obj
    end

    def message
      str = @obj.call_pione_method("as_string")
      "method \"%s\" is not found in %s" % [@name, str]
    end
  end

  # Type is a class for type expression of PIONE model objects.
  class Type < Pione::PioneObject
    attr_reader :type_string
    attr_reader :method_interface
    attr_reader :method_body

    def initialize(type_string)
      @type_string = type_string
      @method_interface = {}
      @method_body = {}
    end

    def match(other)
      other == TypeAny || @type_string == other.type_string
    end

    # Defines pione model object methods.
    # @param [String] name method name
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
    def check(data)
      unless match(data.pione_model_type)
        raise PioneModelTypeError.new(data, self)
      end
    end
  end

  # TypeList represetnts list type of element type.
  class TypeList < Type
    attr_reader :element_type

    def initialize(element_type)
      @element_type = element_type
      super("[%s]" % [element_type.type_string])
    end

    def match(other)
      return false unless other.kind_of?(TypeList)
      @element_type.match(other.element_type)
    end
  end

  # PioneMethodInterface represents type of PIONE object's methods.
  class PioneMethodInterface < Pione::PioneObject
    attr_reader :inputs
    attr_reader :output

    # @param [[Type]] inputs inputs type definition
    # @pram [Type] output type definition
    def initialize(inputs, output)
      @inputs = inputs
      @output = output
    end

    # Validates inputs data types for the method.
    def validate_inputs(*args)
      @inputs.each_with_index do |input, i|
        unless input.match(args[i].pione_model_type)
          raise PioneModelTypeError.new(args[i], input)
        end
      end
    end

    # Validates output data type for the method.
    def validate_output(value)
      @output.match(value.pione_model_type)
    end
  end

  TypeBoolean = Type.new("boolean")
  TypeInteger = Type.new("integer")
  TypeFloat = Type.new("float")
  TypeString = Type.new("string")
  TypeDataExpr = Type.new("data-expr")
  TypeFeature = Type.new("feature")
  TypeRuleExpr = Type.new("rule-expr")
  TypeParameters = Type.new("parameters")

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

  class PioneModelObject < Pione::PioneObject
    def initialize(&b)
      instance_eval(&b) if block_given?
    end

    # Returns self.
    # @param [VariableTable] vtable variable table for evaluation
    # @return [PioneModelObject]
    def eval(vtable=VariableTable.new)
      return self
    end

    # Return true if the object is atomic.
    def atomic?
      true
    end

    def include_variable?
      false
    end

    def set_document_path(path)
      @__document_path__ = path
    end

    def set_line_and_column(line_and_column)
      @__line__, @__column__ = line_and_column
    end

    def line
      @__line__
    end

    def column
      @__column__
    end

    # Calls pione model object method.
    # @param [String] name method name
    # @param [Array] args method's arguments
    # @return [Object] method's result
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
  end

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
end
