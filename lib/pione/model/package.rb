module Pione::Model
  class Package < PioneModelObject
    attr_reader :name
    set_pione_model_type TypePackage

    def initialize(name)
      @name = name
      super()
    end

    def task_id_string
      "Package<#{@name}>"
    end

    def textize
      "package(\"%s\")" % [@name]
    end

    def +(other)
      raise ArgumentError.new(other) unless other.kind_of?(RuleExpr)
      "#{@name}:#{other.name}"
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @name == other.name
    end

    alias :eql? :==

    def hash
      @value.hash
    end
  end
end
