module Pione::Model
  class PioneBoolean < PioneModelObject
    attr_reader :value
    set_pione_model_type TypeBoolean

    def self.true
      new(true)
    end

    def self.false
      new(false)
    end

    def self.not(boolean)
      new(not(boolean.value))
    end

    def self.or(*args)
      new(args.any?{|arg| arg.true?})
    end

    def self.and(*args)
      new(args.all?{|arg| arg.true?})
    end

    def initialize(value)
      @value = value
      super()
    end

    def task_id_string
      "Boolean<#{@value}>"
    end

    def textize
      @value.to_s
    end

    def true?
      @value == true
    end

    def false?
      @value == false
    end

    def to_ruby
      return @value
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @value == other.value
    end

    alias :eql? :==

    def hash
      @value.hash
    end

    #
    # pione methods
    #

    define_pione_method("==", [TypeBoolean], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value == other.value)
    end

    define_pione_method("!=", [TypeBoolean], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("&&", [TypeBoolean], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value && other.value)
    end

    define_pione_method("||", [TypeBoolean], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.value || other.value)
    end

    define_pione_method("and", [TypeBoolean], TypeBoolean) do |rec, other|
      rec.call_pione_method("&&", other)
    end

    define_pione_method("or", [TypeBoolean], TypeBoolean) do |rec, other|
      rec.call_pione_method("||", other)
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.value.to_s)
    end

    define_pione_method("not", [], TypeBoolean) do |rec|
      PioneBoolean.not(rec)
    end
  end
end
