module Pione::Model
  # RuleIOElement is a special PIONE model object for matched data name result.
  class RuleIOElement < BasicModel
    set_pione_model_type TypeRuleIOElement

    attr_accessor :name
    attr_accessor :uri
    attr_accessor :match

    # Creates a element with the name.
    # @param [PioneString, String] name
    #   element name
    def initialize(name)
      @name = name.kind_of?(PioneString) ? name : PioneString.new(name)
      @uri = PioneString.new("")
      @match = PioneList.new()
    end

    # @api private
    def textize
      "rule-io-element(%s,%s,%s)" % [@name.to_ruby, @uri.textize, @match.textize]
    end

    # @api private
    def uri=(uri)
      @uri = uri.to_pione
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      @name == other.name && @uri == other.uri && @match == other.match
    end

    alias :eql? :"=="

    # @api private
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

    define_pione_method("match", [], TypeList.new(TypeString)) do |rec|
      rec.match
    end

    define_pione_method("MATCH", [], TypeList.new(TypeString)) do |rec|
      rec.call_pione_method("match")
    end

    define_pione_method("[]", [TypeInteger], TypeAny) do |rec, i|
      rec.match[i.value-1]
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      rec.name
    end
  end

  # RuleIOList is a input or output list for RuleIOElement.
  class RuleIOList < BasicModel
    extend Forwardable

    set_pione_model_type TypeRuleIOList

    attr_accessor :elements
    def_delegators :@elements, :[], :size, :length

    # Creates a list object.
    # @param [Array<RuleIOElement>] elts
    #   list elements
    def initialize(elts = [])
      @elements = elts
    end

    # Returns new list which appended the element.
    # @param [RuleIOElement] elt
    #   target element
    # @return [RuleIOList]
    #   new list object that added the element
    def add(elt)
      unless elt.kind_of?(RuleIOElement) || elt.kind_of?(self.class)
        raise ArgumentError.new(elt)
      end
      self.class.new(@elements + [elt])
    end

    # Adds the element to this list.
    # @param [RuleIOElement] elt
    #   target element
    # @return [void]
    def add!(elt)
      unless elt.kind_of?(RuleIOElement) || elt.kinf_of?(self.class)
        raise ArgumentError.new(elt)
      end
      @elements << elt
    end

    # @api private
    def textize
      "rule-io-list(%s)" % @elements.map{|elt|
        elt.textize
      }.join(DataExpr::SEPARATOR)
    end

    # @api private
    def ==(other)
      return false unless other.kind_of?(self.class)
      @elements == other.elements
    end

    alias :eql? :"=="

    # @api private
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

    define_pione_method("join", [TypeString], TypeString) do |rec, connective|
      PioneString.new(
        rec.elements.map{|elt|
          elt.call_pione_method("as_string").to_ruby
        }.join(connective.to_ruby)
      )
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
