module Pione
  module Model
    class Constraints
      class << self
        def empty
          new([])
        end
      end

      def initialize(exprs)
        @exprs = exprs
      end

      def satisfy?(vtable)
        @exprs.all? do |expr|
          res = expr.eval(vtable)
          res.kind_of?(PioneBoolean) and res.true?
        end
      end
    end
  end
end
