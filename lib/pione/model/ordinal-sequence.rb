module Pione
  module Model
    class OrdinalSequence < Sequence
      set_index_type TypeInteger
      define_sequence_attribute :separator, " "

      # @param elements [Array<Element>]
      #   sequence elements
      # @param attribute [Hash]
      #   sequence attribute
      def initialize(elements, attribute={})
        super(elements, attribute)
      end
    end

    TypeOrdinalSequence.instance_eval do
      define_pione_method("==", [:receiver_type], TypeBoolean) do |vtable, rec, other|
        if rec.elements.size == other.elements.size
          rec.elements.size.times.all? do |i|
            rec.elements[i] == other.elements[i]
          end.tap {|x| break BooleanSequence.new([PioneBoolean.new(x)])}
        else
          BooleanSequence.new([PioneBoolean.new(false)])
        end
      end

      define_pione_method("nth", [TypeInteger], :receiver_type) do |vtable, rec, index|
        map1(index) {|elt| elt.value == 0 ? rec : rec.elements[elt.value-1]}
      end

      define_pione_method("[]", [:index_type], :receiver_type) do |vtable, rec, index|
        rec.call_pione_method(vtable, "nth", index)
      end

      define_pione_method("reverse", [], :receiver_type) do |vtable, rec|
        rec.class.new(rec.elements.reverse, rec.attribute)
      end

      define_pione_method("head", [], :receiver_type) do |vtable, rec|
        rec.class.new([rec.elements[0]], rec.attribute)
      end

      define_pione_method("tail", [], :receiver_type) do |vtable, rec|
        # NOTE: #tail should fail when the sequence length is less than 1
        rec.class.new(rec.elements[1..-1], rec.attribute)
      end

      define_pione_method("last", [], :receiver_type) do |vtable, rec|
        rec.class.new([rec.elements[-1]], rec.attribute)
      end

      define_pione_method("init", [], :receiver_type) do |vtable, rec|
        # NOTE: #init should fail when the sequence length is less than 1
        rec.class.new(rec.elements[0..-2], rec.attribute)
      end

      define_pione_method("type", [], TypeString) do |vtable, rec|
        case rec
        when StringSequence
          "string"
        when IntegerSequence
          "integer"
        when FloatSequence
          "float"
        when BooleanSequence
          "boolean"
        when DataExprSequence
          "data-expr"
        else
          "undefined"
        end.tap {|x| break PioneString.new(x).to_seq}
      end
    end
  end
end
