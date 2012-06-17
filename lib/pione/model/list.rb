module Pione::Model
  class PioneList < PioneModelObject
    attr_reader :value

    def initialize(*value)
      @value = value
    end

    def pione_model_type
      type = @value.empty? ? TypeAny : @value.first.pione_model_type
      TypeList.new(type)
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @value == other.value
    end

    alias :eql? :==

    def hash
      @value.hash
    end
  end
end
