module Pione
  module Lang
    # OridinalSequence is a sequence that has an ordinal number index.
    class OrdinalSequence < Sequence
      index_type TypeInteger
      member :separator, default: " "

      class << self
        # Build a sequence with arguments. The arguments can be values or pieces.
        def of(*args)
          # map objects to pieces and create a sequece with it
          new(pieces: args.map {|arg| make_piece(arg)})
        end

        # Map pieces of the sequence by applying the block and build a new
        # sequence with it.
        def map(seq, &b)
          of(*seq.pieces.map{|piece| b.call(piece)})
        end

        # Map pieces of two sequence and build a new sequence with it.
        def map2(seq1, seq2, &b)
          vals = seq1.pieces.map do |piece1|
            seq2.pieces.map do |piece2|
              b.call(piece1, piece2)
            end
          end.flatten
          of(*vals)
        end

        def map3(seq1, seq2, seq3, &b)
          vals = seq1.pieces.map do |piece1|
            seq2.pieces.map do |piece2|
              seq3.pieces.map do |piece3|
                b.call(piece1, piece2, piece3)
              end
            end
          end.flatten
          of(*vals)
        end

        # Fold pieces with the init sequence.
        def fold(init, seq, &b)
          seq.pieces.inject(init) do |_seq, piece|
            b.call(_seq, piece)
          end
        end

        # Fold pieces of two sequences with the init sequence.
        def fold2(init, seq1, seq2, &b)
          seq1.pieces.inject(init) do |_seq1, piece1|
            seq2.pieces.inject(_seq1) do |_seq2, piece2|
              b.call(_seq2, piece1, piece2)
            end
          end
        end

        def make_piece(val)
          if val.is_a?(Piece)
            val
          else
            klass = piece_classes.first
            klass.new({klass.members.first => val})
          end
        end
      end

      forward :class, :make_piece

      # Return the sequecen with no pieces.
      def empty
        set(pieces: [])
      end

      # Map my pieces by applying the block.
      def map(&b)
        set(pieces: pieces.map{|piece| make_piece(b.call(piece))})
      end

      # Map by the sequence and build a new sequence of result piece based on self.
      def map_by(seq, &b)
        # build new pieces by applying the block
        _pieces = seq.pieces.map {|piece| make_piece(b.call(piece))}

        # create a new sequence
        set(pieces: _pieces)
      end

      # Map my pieces and other pieces.
      def map2(other, &b)
        _pieces = pieces.map do |piece1|
          other.pieces.map do |piece2|
            make_piece(b.call(piece1, piece2))
          end
        end.flatten
        set(pieces: _pieces)
      end

      def map3(other1, other2, &b)
        _pieces = pieces.map do |piece1|
          other1.pieces.map do |piece2|
            other2.pieces.map do |piece3|
              make_piece(b.call(piece1, piece2, piece3))
            end
          end
        end.flatten
        set(pieces: _pieces)
      end

      # Fold my pieces with initial sequence.
      def fold(init, &b)
        pieces.inject(init) {|_seq, piece| b.call(_seq, piece)}
      end

      # Fold my pieces and other pieces with initial sequence.
      def fold2(init, other, &b)
        pieces.inject(init) do |_seq1, piece1|
          other.pieces.inject(_seq1) do |_seq2, piece2|
            b.call(_seq2, piece1, piece2)
          end
        end
      end

      def inspect
        "#%s%s" % [self.class.name.split("::").last, to_h.inspect]
      end
    end

    TypeOrdinalSequence.instance_eval do
      define_pione_method("==", [:receiver_type], TypeBoolean) do |env, rec, other|
        if rec.pieces.size == other.pieces.size
          rec.pieces.size.times.all? do |i|
            rec.pieces[i] == other.pieces[i]
          end.tap {|x| break BooleanSequence.of(x)}
        else
          BooleanSequence.of(false)
        end
      end

      define_pione_method("==*", [:receiver_type], TypeBoolean) do |env, rec, other|
        case [rec.distribution, other.distribution]
        when [:each, :each]
          rec.pieces.any? do |rec_piece|
            other.pieces.any? {|other_piece| rec_piece == other_piece}
          end.tap {|x| break BooleanSequence.of(x)}
        when [:all, :each]
          BooleanSequence.of(other.pieces.any? {|piece| rec.pieces == [piece]})
        when [:each, :all]
          BooleanSequence.of(rec.pieces.any? {|piece| other.pieces == [piece]})
        when [:all, :all]
          rec.call_pione_method(env, "==", [other])
        end
      end

      define_pione_method("nth", [TypeInteger], :receiver_type) do |env, rec, index|
        rec.map_by(index) {|piece| piece.value == 0 ? rec : rec.pieces[piece.value-1]}
      end

      define_pione_method("[]", [:index_type], :receiver_type) do |env, rec, index|
        rec.call_pione_method(env, "nth", [index])
      end

      define_pione_method("reverse", [], :receiver_type) do |env, rec|
        rec.set(pieces: rec.pieces.reverse)
      end

      define_pione_method("head", [], :receiver_type) do |env, rec|
        rec.set(pieces: [rec.pieces[0]])
      end

      define_pione_method("tail", [], :receiver_type) do |env, rec|
        # NOTE: #tail should fail when the sequence length is less than 1
        rec.set(pieces: rec.pieces[1..-1])
      end

      define_pione_method("last", [], :receiver_type) do |env, rec|
        rec.set(pieces: [rec.pieces[-1]])
      end

      define_pione_method("init", [], :receiver_type) do |env, rec|
        # NOTE: #init should fail when the sequence length is less than 1
        rec.set(pieces: rec.pieces[0..-2])
      end

      define_pione_method("type", [], TypeString) do |env, rec|
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
        end.tap {|x| break StringSequence.of(x)}
      end
    end
  end
end
