module Pione::Model
  class RuleIOElement < PioneModelObject
    set_pione_model_type TypeRuleIOElement

    attr_accessor :name
    attr_accessor :uri
    attr_accessor :match

    def initialize(name)
      @name = name.kind_of?(PioneString) ? name : PioneString.new(name)
      @uri = PioneString.new("")
      @match = PioneList.new()
    end

    def textize
      "ioelement(%s,%s,%s)" % [@name.to_ruby, @uri.textize, @match.textize]
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @name == other.name && @uri == other.uri && @match == other.match
    end

    alias :eql? :==

    def hash
      @value.hash
    end

    #
    # pione method
    #

    define_pione_method("==", [TypeRuleIOElement], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.values == other.values)
    end

    define_pione_method("!=", [TypeRuleIOElement], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("uri", [], TypeString) do |rec, other|
      PioneString.new(rec.uri)
    end

    define_pione_method("match", [], TypeList.new(TypeString)) do |rec, other|
      PioneList.new(*rec.match)
    end

    define_pione_method("MATCH", [], TypeList.new(TypeString)) do |rec, other|
      rec.call_pione_method("match")
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      rec.name
    end
  end

  class RuleIOList < PioneModelObject
    set_pione_model_type TypeRuleIOList

    attr_accessor :elements

    def initialize(elts = [])
      @elements = elts
    end

    # Returns new list which appended the element.
    def add(elt)
      unless elt.kind_of?(RuleIOElement) || elt.kind_of?(self.class)
        raise ArgumentError.new(elt)
      end
      self.class.new(@elements + [elt])
    end

    # Adds the element to this list.
    def add!(elt)
      unless elt.kind_of?(RuleIOElement) || elt.kinf_of?(self.class)
        raise ArgumentError.new(elt)
      end
      @elements << elt
    end

    def textize
      "rule-io-list(%s)" % @elements.map{|elt|
        elt.textize
      }.join(DataExpr::SEPARATOR)
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @elements == other.elements
    end

    alias :eql? :==

    def hash
      @elements.hash
    end

    #
    # pione method
    #

    define_pione_method("==", [TypeRuleIOList], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec.values == other.values)
    end

    define_pione_method("!=", [TypeRuleIOList], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("[]", [TypeInteger], TypeAny) do |rec, i|
      rec.elements[i.value-1]
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(
        rec.elements.map{|elt|
          elt.call_pione_method("as_string").to_ruby
        }.join(DataExpr::SEPARATOR)
      )
    end
  end
end
