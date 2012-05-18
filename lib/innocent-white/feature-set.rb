require 'innocent-white/common'

module InnocentWhite
  class FeatureSet < InnocentWhiteObject
    # Create a feature set.
    # [+*args+] feature list
    def initialize(*args)
      @set = args.to_set
    end

    # Convert into a set.
    def to_set
      @set
    end

    # Convert into an array.
    def to_a
      @set.to_a
    end

    # Compare other object by criteria that self is a superset of it.
    def ===(other)
      return false unless other.respond_to?(:to_a)
      @set.superset?(other.to_a.to_set)
    end

    # :nodoc:
    def ==(other)
      return false unless other.kind_of?(self.class)
      @set == other.list
    end

    # :nodoc:
    alias :eql? :==

    # :nodoc
    def hash
      @set.hash
    end
  end
end
