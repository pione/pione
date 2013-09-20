module Pione
  module Lang
    # KeyedSequence is a sequence that have key and value pairs.
    class KeyedSequence < Sequence
      pione_type TypeKeyedSequence

      member :pieces, default: {}
      member :piece_type

      # Concatenate the sequence and another one.
      #
      # @param other [Sequence]
      #   other sequence
      # @return [Sequence]
      #   a new sequence that have members of self and other
      def concat(other)
        set(pieces: pieces.merge(other.pieces))
      end
      alias :+ :concat

      # Get the element by the key.
      def get(key)
        pieces[key] || (raise IndexError.new(key))
      end

      # Put the element to the sequecence.
      def put(key, val)
        raise ArgumentError.new(key) unless key.kind_of?(Sequence)
        raise ArgumentError.new(val) unless val.kind_of?(Sequence)
        begin
          set(pieces: pieces.merge({key => get(key) + val}))
        rescue IndexError
          set(pieces: pieces.merge({key => val}))
        end
      end

      # Iterate each elements.
      def each
        if block_given?
          pieces.each {|key, val| yield set(pieces: {key => val})}
        else
          Enumerator.new(self, :each)
        end
      end

      def index_type
        pieces.keys.first.pione_type
      end

      def element_type
        pieces.values.first.pione_type
      end

      def eval(env)
        _pieces = pieces.inject({}) do |_pieces, (key, val)|
          _pieces.update({key => val.map{|v| v.eval(env)}})
        end
        set(pieces: _pieces)
      end

      def textize
        inspect
      end

      def inspect
        name = "KeyedSequence"
        content = pieces.map {|key, val| "%s:(%s)" % [key.pieces.first.value, val.textize]}.join(",")
        "#<%s [%s]>" % [name, content]
      end
    end

    TypeKeyedSequence.instance_eval do
      define_pione_method("keys", [], :index_type) do |env, rec|
        rec.pieces.keys.inject{|s1, s2| s1 + s2}
      end

      define_pione_method("values", [], :element_type) do |env, rec|
        rec.pieces.values.inject{|s1, s2| s1 + s2}
      end

      # [] : index_type -> element_type
      define_pione_method("[]", [:index_type], :element_type) do |env, rec, index|
        index.pieces.map do |index_elt|
          rec.pieces[index.set(pieces: [index_elt])] || (raise IndexError.new(index_elt))
        end.inject{|res, seq| res + seq}
      end

      define_pione_method("textize", [], TypeString) do |env, rec|
        rec.call_pione_method(env, "values", []).call_pione_method(env, "textize", [])
      end
    end
  end
end
