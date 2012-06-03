require 'innocent-white/common'

module InnocentWhite
  class FeatureExpr
    attr_reader :next
    attr_reader :type
    attr_reader :identifier

    def initialize(identifier, type, next_expr=nil)
      @identifier = identifier
      @type = type
      @next = next_expr
    end

    def or(feature_expr)
      new(@identifier, @type, feature_expr)
    end

    def requisite?
      @type == :requisite
    end

    def preferred?
      @type == :preferred
    end

    def exclusive?
      @type == :exclusive
    end

    def selective?

    end

    def ==(other)
      @type == other.type && @identifier == other.identifier
    end

    def ===(feature)
      # match test of this expression
      case @type
      when :requisite
        return true if @identifier == feature
      when :preferred
        return true
      when :exclusive
        return true unless @identifier == feature
      end
      # match test of next expression
      return @next.match(feature) if @next
      # failed
      return false
    end

    alias :match :===
  end
end
