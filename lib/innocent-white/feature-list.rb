require 'innocent-white/common'

module InnocentWhite
  class FeatureList < InnocentWhiteObject
    def initialize(*args)
      @list = args
    end

    def to_a
      @list
    end

    def ===(other)
      return false unless other.renpond_to?(:to_a)
      other_list = other.to_a
      @list.include?(other_list.include?)
    end

    # :nodoc:
    def ==(other)
      return false unless other.kind_of?(FeatureList)
      @list == other.list
    end

    # :nodoc:
    alias :eql? :==

    # :nodoc
    def hash
      @inputs.hash + @outputs.hash + @params.hash + @content.hash
    end
  end
end
