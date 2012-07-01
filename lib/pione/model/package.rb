module Pione::Model
  class Package < PioneModelObject
    attr_reader :name

    def initialize(name)
      @name = name
    end

    def pione_model_type
      TypePackage
    end

    def ==(other)
      @name == other.name
    end

    alias :eql? :==

    def hash
      @value.hash
    end
  end
end
