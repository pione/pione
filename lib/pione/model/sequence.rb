module Pione
  module Model
    # SequenceAttributeError is an exception for attribute mismatching.
    class SequenceAttributeError < StandardError
      def initialize(attribute)
        @attribute = attribute
      end

      def message
        "attribute mismatched: %s" % @attribute
      end
    end

    # Sequence is a base class for all expressions.
    class Sequence < Callable
      include Enumerable

      class << self
        # Copy sequence attribute to subclass.
        def inherited(subclass)
          @sequence_attribute.each do |name, vals|
            subclass.define_sequence_attribute(name, *vals)
          end
          subclass.set_index_type index_type
        end

        # Define sequence attribute.
        #
        # @param name [Symbol]
        #    attribute name
        # @param default_value [Symbol]
        #    default value of the attribute
        # @param other_values [Array<Symbol>]
        #    other values of the attribute
        # @return [void]
        def define_sequence_attribute(name, default_value, *other_values)
          @sequence_attribute ||= {}
          @sequence_attribute[name] = [default_value] + other_values

          define_method(name) do
            @attribute[name]
          end

          define_method("set_%s" % name) do |value|
            self.class.new(@elements, @attribute.merge({name => value}))
          end

          # define additional methods when values are symbols
          if default_value.kind_of?(Symbol)
            ([default_value] + other_values).each do |value|
              define_method("%s?" % value) do
                @attribute[name] == value
              end

              define_method("set_%s" % value) do
                self.class.new(@elements, @attribute.merge({name => value}))
              end
            end
          end
        end

        attr_reader :element_class
        attr_reader :sequence_attribute
        attr_reader :shortname
        attr_reader :index_type

        # Set element class.
        #
        # @param klass [Class]
        #   element class
        # @return [void]
        def set_element_class(klass)
          @element_class = klass
          klass.set_sequence_class(self)
        end

        # Set the shortname.
        #
        # @param name [String]
        #   shortname
        # @return [void]
        def set_shortname(name)
          @shortname = name
        end

        # Set the index type.
        #
        # @param index_type [Type]
        #   index type
        # @return [void]
        def set_index_type(index_type)
          @index_type = index_type
        end

        # Make an empty sequence.
        def empty(attributes={})
          new([], attributes)
        end
      end

      # Make a void sequence.
      def Sequence.void
        Sequence.new([])
      end

      define_sequence_attribute :distribution, :each, :all
      forward! :class, :sequence_attribute, :shortname, :index_type
      forward! :@elements, :first, :[], :empty?
      attr_reader :elements
      attr_reader :attribute

      # @param elements [Array]
      #   sequence elements
      # @param attribute [Hash]
      #   sequence attribute
      def initialize(elements, attribute={})
        @elements = elements
        @attribute = Hash.new.merge(attribute)

        # clear unneeded keys
        (attribute.keys - sequence_attribute.keys).each do |key|
          @attribute.delete(key)
        end

        # fill default value
        sequence_attribute.each do |name, values|
          @attribute[name] ||= values.first
        end
      end


      # Return true if the sequence is void.
      #
      # @return [Boolean]
      #   true if the sequence is void
      def void?
        self.class == Sequence and empty?
      end

      # Concatenate another sequence.
      #
      # @param other [Sequence]
      #   other sequence
      # @return [Sequence]
      #   a new sequence that have members of self and other
      def concat(other)
        raise SequenceAttributeError.new(other) unless @attribute == other.attribute
        self.class.new(@elements + other.elements, @attribute)
      end

      # Push the element to the sequecence.
      #
      # @param element [Element]
      #    the element
      # @return [Sequence]
      #    a new sequence that have member self and the element.
      def push(element)
        self.class.new(@elements + [element], @attribute)
      end

      # Iterate each elements.
      #
      # @return [Enumerator]
      #   return an enumerator if the block is not given
      def each
        if block_given?
          @elements.each {|e| yield self.class.new([e], @attribute)}
        else
          Enumerator.new(self, :each)
        end
      end

      def eval(vtable)
        self.class.new(@elements.map{|elt| elt.eval(vtable)}, @attribute)
      end

      def include_variable?
        @elements.any?{|elt| elt.include_variable?}
      end

      def ==(other)
        return false unless other.kind_of?(self.class)
        return false unless @elements == other.elements
        return @attribute == other.attribute
      end
      alias :eql? :"=="

      def hash
        @elements.hash + @attribute.hash
      end

      def task_id_string
        "<#{@elements}, #{@attribute}>"
      end

      def textize
        "<%s [%s]>" % [shortname, @elements.map{|x| x.textize}.join(",")]
      end

      def inspect
        "#<%s %s %s>" % [shortname, @elements, @attribute]
      end
    end

    TypeSequence.instance_eval do
      define_pione_method("!=", [:receiver_type], TypeBoolean) do |rec, other|
        rec.call_pione_method("==", other).call_pione_method("not")
      end

      define_pione_method("|", [:receiver_type], :receiver_type) do |rec, other|
        rec.concat(other)
      end

      define_pione_method("each", [], :receiver_type) do |rec|
        rec.set_each
      end

      define_pione_method("each?", [], TypeBoolean) do |rec|
        BooleanSequence.new([PioneBoolean.new(rec.each?)])
      end

      define_pione_method("all", [], :receiver_type) do |rec|
        rec.set_all
      end

      define_pione_method("all?", [], TypeBoolean) do |rec|
        BooleanSequence.new([PioneBoolean.new(rec.all?)])
      end

      define_pione_method("i", [], TypeInteger) do |rec|
        rec.call_pione_method("as_integer")
      end

      define_pione_method("f", [], TypeFloat) do |rec|
        rec.call_pione_method("as_float")
      end

      define_pione_method("str", [], TypeString) do |rec|
        rec.call_pione_method("as_string")
      end

      define_pione_method("d", [], TypeDataExpr) do |rec|
        rec.call_pione_method("as_data_expr")
      end

      define_pione_method("length", [], TypeInteger) do |rec|
        IntegerSequence.new([PioneInteger.new(rec.elements.size)])
      end

      define_pione_method("[]", [:index_type], :receiver_type) do |rec, index|
        rec.call_pione_method("nth", index)
      end

      define_pione_method("member?", [:receiver_type], TypeBoolean) do |rec, target|
        sequential_map1(TypeBoolean, target) do |target_elt|
          rec.elements.map{|elt| elt.value}.include?(target_elt.value)
        end
      end

      define_pione_method(":", [TypeSequence], TypeKeyedSequence) do |keys, vals|
        keys.elements.map do |key_elt|
          vals.elements.map do |val_elt|
            KeyedSequence.new(key_elt => [val_elt])
          end
        end.flatten.inject(KeyedSequence.new({})){|seq, _seq| seq.concat(_seq)}
      end

      define_pione_method("textize", [], TypeString) do |rec|
        rec.call_pione_method("as_string").call_pione_method("join", PioneString.new(rec.separator).to_seq)
      end
    end
  end
end
