module Pione::Model
  # PioneString is a string value in PIONE system.
  class PioneString < BasicModel
    set_pione_model_type TypeString
    attr_reader :value

    # Creates a string with the value.
    # @param [String] value
    #   string value
    def initialize(value)
      @value = value
      super()
    end

    # Evaluates the object with the variable table.
    # @param [VariableTable] vtable
    #   variable table for evaluation
    # @return [BasicModel]
    #   evaluation result
    def eval(vtable)
      self.class.new(vtable.expand(@value))
    end

    # Returns true if the value includes variables.
    # @return [Boolean]
    #   true if the value includes variables
    def include_variable?
      VariableTable.check_include_variable(@value)
    end

    # @api private
    def task_id_string
      "String<#{@value}>"
    end

    # @api private
    def textize
      "\"%s\"" % [@value]
    end

    # Returns ruby's value.
    # @return [String]
    #   the value in ruby
    def to_ruby
      return @value
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      @value == other.value
    end

    alias :eql? :"=="

    # @api private
    def hash
      @value.hash
    end
  end

  TypeString.instance_eval do
    define_pione_method("==", [TypeString], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value == other.value)
    end

    define_pione_method("!=", [TypeString], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("+", [TypeString], TypeString) do |rec, other|
      PioneString.new(rec.value + other.value)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      rec
    end

    define_pione_method("as_int", [], TypeInteger) do |rec|
      PioneInteger.new(rec.value.to_i)
    end

    define_pione_method("as_float", [], TypeFloat) do |rec|
      PioneFloat.new(rec.value.to_f)
    end

    define_pione_method("length", [], TypeInteger) do |rec|
      PioneInteger.new(rec.value.size)
    end

    define_pione_method("include?", [TypeString], TypeBoolean) do |rec, str|
      PioneBoolean.new(rec.value.include?(str.value))
    end

    define_pione_method("substring",
                        [TypeInteger, TypeInteger],
                        TypeString) do |rec, nth, len|
      PioneString.new(rec.value[nth.value, len.value])
    end
  end
end

# String extention for PIONE system.
class String
  # Returns PIONE's value.
  # @return [PioneString]
  #   PIONE's value
  def to_pione
    PioneString.new(self)
  end
end
