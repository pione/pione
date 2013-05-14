module Pione
  module Model
    # KeyedSequence is a sequence that have key and value pairs.
    class KeyedSequence < Sequence
      set_pione_model_type TypeKeyedSequence
      set_shortname "KeyedSeq"

      class << self
        def empty(attributes={})
          new({}, attributes)
        end
      end

      # @param elements [Hash{Element => Sequence}]
      #   sequence elements
      # @param attribute [Hash]
      #   sequence attribute
      def initialize(elements, attribute={})
        raise ArgumentError.new(elements) unless elements.kind_of?(Hash)
        @elements = elements
        @attribute = Hash.new.merge(attribute)

        # fill default value
        sequence_attribute.each do |name, values|
          @attribute[name] ||= values.first
        end
      end

      def index_type
        ordinal_sequence_of_element(@elements.keys.first).pione_model_type
      end

      def element_type
        ordinal_sequence_of_element(@elements.values.flatten.first).pione_model_type
      end

      def ordinal_sequence_of_element(elt)
        case elt
        when PioneInteger
          IntegerSequence
        when PioneString
          StringSequence
        when PioneFloat
          FloatSequence
        when PioneBoolean
          BooleanSequence
        when DataExpr
          DataExprSequence
        else
          raise ArgumentError.new(elt)
        end
      end

      # Concatenate the sequence and another one.
      #
      # @param other [Sequence]
      #   other sequence
      # @return [Sequence]
      #   a new sequence that have members of self and other
      def concat(other)
        raise SequenceAttributeError.new(other) unless @attribute == other.attribute
        new_elements = (@elements.to_a + other.elements.to_a).inject({}) do |elts, list|
          key, vals = list
          elts[key] = (elts[key] ||= []) + vals
          elts
        end
        self.class.new(new_elements, @attribute)
      end

      # Get the element by the key.
      #
      # @param key [Element]
      #   index key
      # @return [BasicModel]
      #   element
      def get(key)
        @elements[key] || []
      end

      # Put the element to the sequecence.
      #
      # @param key [Element]
      #   the key
      # @param element [Element]
      #   the element
      # @return [Sequence]
      #   a new sequence that have member self and the element.
      def put(key, element)
        raise ArgumentError.new(element) unless element.kind_of?(Element)
        self.class.new(@elements.merge({key => get(key) + [element]}), @attribute)
      end

      # Iterate each elements.
      #
      # @return [Enumerator]
      #   return an enumerator if the block is not given
      def each
        if block_given?
          @elements.each {|key, val| yield self.class.new({key => val}, @attribute)}
        else
          Enumerator.new(self, :each)
        end
      end

      def eval(vtable)
        new_elements = @elements.inject({}) do |elts, key, val|
          elts[key.eval(vtable)] = val.eval(vtable)
        end
        self.class.new(new_elements, @attribute)
      end

      def include_variable?
        @elements.any?{|key, value| key.include_variable? or val.include_variable?}
      end

      def textize
        inspect
      end

      def inspect
        "#<%s [%s] %s>" % [shortname, @elements.map{|key, vals| "%s:(%s)" % [key.textize, vals.map{|val| val.textize}.join("|")]}.join(","), @attribute]
      end
    end

    TypeKeyedSequence.instance_eval do
      # keys : index_type
      define_pione_method("keys", [], :index_type) do |rec|
        keys = rec.elements.keys
        rec.ordinal_sequence_of_element(keys.first).new(keys)
      end

      # values : element_type
      define_pione_method("values", [], :element_type) do |rec|
        vals = rec.elements.values.flatten
        rec.ordinal_sequence_of_element(vals.first).new(vals)
      end

      # [] : index_type -> element_type
      define_pione_method("[]", [:index_type], :element_type) do |rec, index|
        index.elements.map do |index_elt|
          rec.elements[index_elt]
        end.flatten.tap{|x| break rec.ordinal_sequence_of_element(x.first).new(x, rec.attribute)}
      end
    end
  end
end
