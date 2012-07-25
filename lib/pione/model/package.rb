module Pione::Model
  class Package < PioneModelObject
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def pione_model_type
      TypePackage
    end

    def task_id_string
      "Package<#{@name}>"
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
