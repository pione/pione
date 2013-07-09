module Pione
  module Model
    # PioneFloat represents float values in PIONE system.
    class PioneFloat < Value
      # @api private
      def textize
        "#PioneFloat{%s}" % @value
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @value == other.value
      end

      alias :eql? :"=="

      # @api private
      def hash
        @value.hash
      end
    end

    class FloatSequence < OrdinalSequence
      set_pione_model_type TypeFloat
      set_element_class PioneFloat
      set_shortname "FSeq"

      def self.of(*args)
        new(args.map{|arg| arg.kind_of?(PioneFloat) ? arg : PioneFloat.new(arg)})
      end

      def value
        @value ||= @elements.inject(0.0){|n, elt| n + elt.value}
      end
    end

    TypeFloat.instance_eval do
      define_pione_method(">", [TypeFloat], TypeBoolean) do |vtable, rec, other|
        BooleanSequence.new([PioneBoolean.new(rec.value > other.value)])
      end

      define_pione_method("<", [TypeFloat], TypeBoolean) do |vtable, rec, other|
        BooleanSequence.new([PioneBoolean.new(rec.value < other.value)])
      end

      define_pione_method("+", [TypeFloat], TypeFloat) do |vtable, rec, other|
        map2(rec, other) do |rec_elt, other_elt|
          PioneFloat.new(rec_elt.value + other_elt.value)
        end
      end

      define_pione_method("-", [TypeFloat], TypeFloat) do |vtable, rec, other|
        map2(rec, other) do |rec_elt, other_elt|
          PioneFloat.new(rec_elt.value - other_elt.value)
        end
      end

      define_pione_method("*", [TypeFloat], TypeFloat) do |vtable, rec, other|
        PioneFloat.new(rec.value * other.value)
      end

      define_pione_method("%", [TypeFloat], TypeFloat) do |vtable, rec, other|
        # TODO: zero division error
        PioneFloat.new(rec.value % other.value)
      end

      define_pione_method("/", [TypeFloat], TypeFloat) do |vtable, rec, other|
        # TODO: zero division error
        PioneFloat.new(rec.value / other.value)
      end

      define_pione_method("as_string", [], TypeString) do |vtable, rec|
        sequential_map1(TypeString, rec) do |elt|
          elt.value.to_s
        end
      end

      define_pione_method("as_integer", [], TypeInteger) do |vtable, rec|
        sequential_map1(TypeInteger, rec) do |elt|
          elt.value.to_i
        end
      end

      define_pione_method("as_float", [], TypeFloat) do |vtable, rec|
        rec
      end

      # sin : float
      define_pione_method("sin", [], TypeFloat) do |vtable, rec|
        sequential_map1(TypeFloat, rec) do |elt|
          Math.sin(elt.value)
        end
      end

      # cos : float
      define_pione_method("cos", [], TypeFloat) do |vtable, rec|
        sequential_map1(TypeFloat, rec) do |elt|
          Math.cos(elt.value)
        end
      end

      # abs : float
      define_pione_method("abs", [], TypeFloat) do |vtable, rec|
        sequential_map1(TypeFloat, rec) {|elt| elt.value.abs}
      end
    end
  end
end
