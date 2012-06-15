module Pione::Model
  class PioneInteger
    attr_reader :i

    def initialize(i)
      @i = i
    end

    def to_ruby
      return @i
    end
  end
end
