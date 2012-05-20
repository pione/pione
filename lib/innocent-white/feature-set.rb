require 'innocent-white/common'

module InnocentWhite
  class FeatureSet < InnocentWhiteObject
    extend Forwardable

    def_delegators(:@set, :empty?, :size)

    # Create a feature set.
    # [+*args+] feature list
    def initialize(*args)
      @set = args.flatten.to_set
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
      return false unless other.respond_to?(:to_set)
      @set.superset?(other.to_set)
    end

    # :nodoc:
    def ==(other)
      return false unless other.kind_of?(self.class)
      @set == other.to_set
    end

    # :nodoc:
    alias :eql? :==

    # :nodoc
    def hash
      @set.hash
    end
  end
end
