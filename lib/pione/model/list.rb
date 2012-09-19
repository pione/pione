module Pione::Model
  class PioneList < PioneModelObject
    set_pione_model_type TypeList[TypeAny]

    attr_reader :values

    # Creates a list with elements.
    # @param [Array] values
    #   elements
    def initialize(*elts)
      unless elts.empty?
        if elts.find{|val| not(val.kind_of?(PioneModelObject))}
          raise ArgumentError.new(elts)
        end
        unless elts.map{|val| val.pione_model_type}.uniq.size == 1
          raise ArgumentError.new(elts)
        end
      end
      @values = elts
    end

    def pione_model_type
      type = @values.empty? ? TypeAny : @values.first.pione_model_type
      TypeList.new(type)
    end

    # Returns true if the list is empty.
    def empty?
      @values.empty?
    end

    # Returns new list which appended the element.
    # @param [PioneModelObject] elt
    #   the element object
    # @return [PioneList]
    #   new list with the element
    def add(elt)
      unless elt.kind_of?(PioneModelObject)
        raise ArgumentError.new(elt)
      end
      unless pione_model_type == elt.pione_model_type
        raise ArgumentError.new(elt)
      end
      self.class.new(@values + [elt])
    end

    # Returns the value of index.
    # @param [Integer] index
    #   index to get the value
    # @return
    #   the value
    def [](index)
      @values[index]
    end

    def size
      @values.size
    end


    # @api private
    def textize
      "[%s]" % @values.map{|val| val.textize}.join(",")
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

    #
    # pione method
    #

    define_pione_method("==", [TypeList[TypeAny]], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.values == other.values)
    end

    define_pione_method("!=", [TypeList[TypeAny]], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("+", [TypeList[TypeAny]], TypeList[TypeAny]) do |rec, other|
      PioneList.new(rec.values + other.values)
    end

    define_pione_method("-", [TypeList[TypeAny]], TypeList[TypeAny]) do |rec, other|
      PioneList.new(rec.values - other.values)
    end

    define_pione_method("*", [TypeList[TypeAny]], TypeList[TypeAny]) do |rec, other|
      PioneList.new(rec.values * other.values)
    end

    define_pione_method("empty?", [], TypeBoolean) do |rec|
      PioneBoolean.new(rec.empty?)
    end

    define_pione_method("[]", [TypeInteger], TypeAny) do |rec, i|
      rec.values[i.value]
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.values.to_s)
    end
  end
end
