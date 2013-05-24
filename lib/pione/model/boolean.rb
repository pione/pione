module Pione
  module Model
    # PioneBoolean representes truth value in PIONE system.
    class PioneBoolean < Value
      # Returns the value in ruby.
      attr_reader :value

      class << self
        # Return true value in PIONE system.
        #
        # @return [PioneBoolean]
        #   true value
        def true
          new(true)
        end

        # Return false value in PIONE system.
        #
        # @return [PioneBoolean]
        #   false value
        def false
          new(false)
        end

        # Return inverse value of it.
        #
        # @param boolean [Boolean]
        #   target value
        # @return [PioneBoolean]
        #   true if the param is false, or false
        def not(boolean)
          new(not(boolean.value))
        end

        # Return true value if arguments include true value.
        #
        # @param args [Array<PioneBoolean>]
        # @return [PioneBoolean]
        #   true value if arguments include true value
        def or(*args)
          new(args.any?{|arg| arg.true?})
        end

        # Return true value if all arguments has true value.
        #
        # @param args [Array<PioneBoolean>]
        # @return [PioneBoolean]
        #   true value if all arguments has true value
        def and(*args)
          new(args.all?{|arg| arg.true?})
        end
      end

      # Create a value.
      #
      # @param value [Boolean]
      #   true or false
      def initialize(value)
        raise ArgumentError.new(value) unless value == true or value == false
        @value = value
      end

      # @api private
      def textize
        @value.to_s
      end

      # Return true if the value is true.
      #
      # @return [Boolean]
      #   true if the value is true
      def true?
        @value == true
      end

      # Return true if the value is false.
      #
      # @return [Boolean]
      #   true if the value is false
      def false?
        @value == false
      end

      def to_seq
        BooleanSequence.new([self])
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

      def inspect
        "#<PioneBoolean %s>" % @value
      end
    end

    class BooleanSequence < OrdinalSequence
      set_pione_model_type TypeBoolean
      set_element_class PioneBoolean
      set_shortname "BSeq"

      def value
        @value ||= @elements.inject(true){|b, elt| b and elt.value}
      end
    end

    #
    # pione methods
    #

    TypeBoolean.instance_eval do
      define_pione_method("and", [TypeBoolean], TypeBoolean) do |vtable, rec, other|
        sequential_map2(TypeBoolean, rec, other) do |rec_elt, other_elt|
          rec_elt.value && other_elt.value
        end
      end

      define_pione_method("or", [TypeBoolean], TypeBoolean) do |vtable, rec, other|
        sequential_map2(TypeBoolean, rec, other) do |rec_elt, other_elt|
          rec_elt.value || other_elt.value
        end
      end

      define_pione_method("as_integer", [], TypeInteger) do |vtable, rec|
        sequential_map1(TypeInteger, rec) {|rec| rec.value ? 1 : 0}
      end

      define_pione_method("as_float", [], TypeFloat) do |vtable, rec|
        sequential_map1(TypeFloat, rec) {|rec| rec.value ? 1.0 : 0.0}
      end

      define_pione_method("as_string", [], TypeString) do |vtable, rec|
        sequential_map1(TypeString, rec) {|rec| rec.value.to_s}
      end

      define_pione_method("as_data_expr", [], TypeDataExpr) do |vtable, rec|
        sequential_map1(TypeDataExpr, rec) {|rec| rec.value.to_s}
      end

      define_pione_method("not", [], TypeBoolean) do |vtable, rec|
        sequential_map1(TypeBoolean, rec) do |elt|
          not(elt.value)
        end
      end

      define_pione_method("every?", [], TypeBoolean) do |vtable, rec|
        PioneBoolean.new(not(rec.elements.include?(PioneBoolean.false))).to_seq
      end

      define_pione_method("any?", [], TypeBoolean) do |vtable, rec|
        PioneBoolean.new(rec.elements.include?(PioneBoolean.true)).to_seq
      end

      define_pione_method("one?", [], TypeBoolean) do |vtable, rec|
        PioneBoolean.new(rec.elements.select{|elt| elt == PioneBoolean.true}.size == 1).to_seq
      end
    end
  end
end
