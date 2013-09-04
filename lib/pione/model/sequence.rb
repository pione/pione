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
    class Sequence < Expr
      include Enumerable         # use iteration
      include Util::Positionable # Sequence have position in source maybe
      include Callable           # provides #call_pione_method
      immutable true

      class << self
        def inherited(subclass)
          members.each {|member_name| subclass.member(member_name, default: default_values[member_name])}
          subclass.immutable true
          subclass.index_type(index_type)
        end

        # Get/set piece class.
        def piece_class(klass)
          (@piece_classes ||= []) << klass
        end

        def piece_classes
          @piece_classes ||= []
        end

        # Set the index type.
        def index_type(type=nil)
          type ? @index_type = type : @index_type
        end
      end

      # Make a void sequence.
      def Sequence.void
        Sequence.new([])
      end

      member :pieces, default: []
      member :distribution, default: :each, values: [:each, :all]

      forward! :class, :piece_classes, :index_type
      forward! Proc.new{pieces}, :size, :length, :include?

      # Return true if the sequence is void.
      #
      # @return [Boolean]
      #   true if the sequence is void
      def void?
        self.class == Sequence and empty?
      end

      # Return true if the sequence is assertive about attributes.
      def assertive?
        true
      end

      def attribute
        members - [:pieces]
      end

      # Concatenate self and another sequence. If self and another are
      # assertive, raise +SequenceAttributeError+ exception when the attributes
      # are different.
      #
      # @param other [Sequence]
      #   other sequence
      # @return [Sequence]
      #   a new sequence that have members of self and other
      def concat(other)
        if assertive? and other.assertive?
          raise SequenceAttributeError.new(other) unless attribute == other.attribute
        end
        attr = not(other.assertive?) ? @attribute : other.attribute
        set(pieces: pieces + other.pieces)
      end
      alias :+ :concat

      # Push the piece to the sequecence.
      def push(piece)
        set(pieces: pieces + [piece])
      end

      # Iterate each elements.
      #
      # @return [Enumerator]
      #   return an enumerator if the block is not given
      def each
        if block_given?
          pieces.each {|e| yield set(pieces: [e])}
        else
          Enumerator.new(self, :each)
        end
      end

      def eval(env)
        set(pieces: pieces.map{|piece| piece.eval(env)})
      end

      # Update pieces with the data.
      def update_pieces(data)
        _pieces = pieces.map do |piece|
          _data = data.inject({}) do |tbl, (key, val)|
            tbl.tap {|x| x[key] = val.kind_of?(Proc) ? val.call(piece) : val}
          end
          piece.set(_data)
        end
        set(pieces: _pieces)
      end
    end

    TypeSequence.instance_eval do
      # Provides not-equal method.
      define_pione_method("!=", [:receiver_type], TypeBoolean) do |env, rec, other|
        rec.call_pione_method(env, "==", [other]).call_pione_method(env, "not", [])
      end

      # Concatenate sequences.
      define_pione_method("|", [:receiver_type], :receiver_type) do |env, rec, other|
        rec + other
      end

      # Set "each" into the distribution.
      define_pione_method("each", [], :receiver_type) do |env, rec|
        rec.set(distribution: :each)
      end

      # Return true if the distribution of sequence is "each".
      define_pione_method("each?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.distribution == :each)
      end

      # Set "all" into the distribution.
      define_pione_method("all", [], :receiver_type) do |env, rec|
        rec.set(distribution: :all)
      end

      # Return true if the distribution of sequence is "all".
      define_pione_method("all?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.distribution == :all)
      end

      # Return the integer sequence.
      define_pione_method("i", [], TypeInteger) do |env, rec|
        rec.call_pione_method(env, "as_integer", [])
      end

      # Return the float sequence.
      define_pione_method("f", [], TypeFloat) do |env, rec|
        rec.call_pione_method(env, "as_float", [])
      end

      # Return the string sequence.
      define_pione_method("str", [], TypeString) do |env, rec|
        rec.call_pione_method(env, "as_string", [])
      end

      # Return the data expression sequence.
      define_pione_method("d", [], TypeDataExpr) do |env, rec|
        rec.call_pione_method(env, "as_data_expr", [])
      end

      # Return length of the sequence.
      define_pione_method("length", [], TypeInteger) do |env, rec|
        IntegerSequence.of(rec.pieces.size)
      end

      # Alias of #nth.
      define_pione_method("[]", [:index_type], :receiver_type) do |env, rec, index|
        rec.call_pione_method(env, "nth", [index])
      end

      # Return boolean sequence that receiver includes the piece of target.
      define_pione_method("member?", [:receiver_type], TypeBoolean) do |env, rec, target|
        BooleanSequence.map(target) {|piece| rec.pieces.include?(piece)}
      end

      # Return true if the sequence is empty.
      define_pione_method("empty?", [], TypeBoolean) do |env, rec|
        BooleanSequence.of(rec.pieces.size == 0)
      end

      # Create a keyed sequence.
      define_pione_method(":", [TypeSequence], TypeKeyedSequence) do |env, key, val|
        key.pieces.map do |key_elt|
          KeyedSequence.new(pieces: {key.set(pieces: [key_elt]) => val})
        end.inject{|s1, s2| s1 + s2}
      end

      # Return PIONE string of the sequence.
      define_pione_method("textize", [], TypeString) do |env, rec|
        # convert pieces to strings
        strings = rec.call_pione_method(env, "as_string", [])

        # join it with separator
        strings.call_pione_method(env, "join", [StringSequence.of(rec.separator)])
      end
    end
  end
end
