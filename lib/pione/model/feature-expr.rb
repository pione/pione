# -*- coding: utf-8 -*-

module Pione
  module Model
    class FeaturePiece < Piece
      piece_type_name "Feature"
      member :name

      class << self
        def feature_type(val = nil)
          val ? @feature_type = val : @feature_type
        end
      end

      forward :class, :feature_type
    end

    #
    # special features
    #

    # SpecialFeature is a class for empty feature and boundless feature.
    class SpecialFeature < FeaturePiece
      class << self
        def symbol(sym=nil)
          sym ? @symbol = sym : sym
        end
      end

      feature_type :both
      forward :class, :symbol

      def textize
        symbol
      end

      def ==(other)
        other.kind_of?(self.class) and symbol == other.symbol
       end
      alias :eql? :==
    end

    # EmptyFeature is a special feature that represents there are no features.
    # This means workers have no specific abilities in provider expression and
    # tasks have no specific requests in request expression.
    class EmptyFeature < SpecialFeature
      symbol "*"
    end

    # AlmightyFeature is a special feature that represents whole features. This
    # means that workers have almighty ability in provider expression and tasks
    # have almighty ability request in request expression.
    class AlmightyFeature < SpecialFeature
      symbol "**"
    end

    #
    # simple features
    #

    # SimpleFeature is a feature that consists prefix and name.
    class SimpleFeature < FeaturePiece
      class << self
        # Return the operator symbol.
        def prefix(val = nil)
          val ? @prefix = val : @prefix
        end
      end

      forward :class, :prefix

      def textize
        "%s%s" % [prefix, name]
      end
    end

    # PossibleFeature is a provider feature that represents workers' possible
    # ability.
    class PossibleFeature < SimpleFeature
      prefix "^"
      feature_type :provider
    end

    # RestrictiveFeature is a provider feature that represents workers'
    # restrictive ability.
    class RestrictiveFeature < SimpleFeature
      prefix "!"
      feature_type :provider
    end

    # RequisiteFeature is a request feature that represents tasks' requisite
    # of ability.
    class RequisiteFeature < SimpleFeature
      prefix "+"
      feature_type :request
    end

    # BlockingFeature is a request feature that represents tasks' nature
    # of blocking workers have the feature name execute the task.
    class BlockingFeature < SimpleFeature
      prefix "-"
      feature_type :request
    end

    # PreferredFeature is a request feature that represents the task is
    # processed by workers prior to other tasks.
    class PreferredFeature < SimpleFeature
      prefix "?"
      feature_type :request
    end

    #
    # complex feature
    #

    # ComplexFeatureMethod
    module ComplexFeatureMethod
      def feature_type
        pieces.inject(:both) {|t, piece| t == :both ? piece.feature_type : t}
      end
    end

    #
    # compound feature
    #

    # CompoundFeature represents conjunction of feature pieces.
    class CompoundFeature < FeaturePiece
      class << self
        def build(piece1, piece2)
          # unify features if they are same
          return piece1 if piece1 == piece2

          # append if either feature is compound
          return piece1.add(piece2) if piece1.is_a?(CompoundFeature)
          return piece2.add(piece1) if piece2.is_a?(CompoundFeature)

          # create new compound feature
          new(pieces: Set.new([piece1, piece2]))
        end
      end

      member :pieces, :default => Set.new

      def add(piece)
        if piece.is_a?(CompoundFeature)
          set(pieces: pieces + piece.pieces)
        else
          set(pieces: pieces + Set.new([piece]))
        end
      end
    end

    #
    # sequence
    #

    # FeatureSequence represents disjunction of feature pieces.
    class FeatureSequence < OrdinalSequence
      pione_type TypeFeature
      piece_class EmptyFeature
      piece_class AlmightyFeature
      piece_class PossibleFeature
      piece_class RestrictiveFeature
      piece_class RequisiteFeature
      piece_class BlockingFeature
      piece_class PreferredFeature

      class << self
        def of(*args)
          args.each {|arg| raise ArgumentError(arg) unless arg.is_a?(FeaturePiece)}
          args.size > 0 ? new(args) : new([EmptyFeature.new])
        end
      end

      include ComplexFeatureMethod

      def concat(other)
        acceptable = feature_type.nil? or feature_type == :both
        other_acceptable = other.feature_type.nil? or other.feature_type == :both
        if feature_type == other.feature_type or acceptable or other_acceptable
          super(other)
        else
          raise SequenceAttributeError.new(other)
        end
      end

      # Return true if the feature accepts other feature.
      def match(other)
        provider_pieces = pieces
        request_pieces = other.pieces

        if feature_type == :request or other.feature_type == :provider
          provider_pieces = other.pieces
          request_pieces = pieces
        end

        provider_pieces = [EmptyFeature.new] if provider_pieces.empty?
        request_pieces = [EmptyFeature.new] if request_pieces.empty?

        provider_pieces.any? do |provider_piece|
          request_pieces.any? do |request_piece|
            _match(provider_piece, request_piece)
          end
        end
      end

      # This alias is for RINDA's template matcher.
      alias :"===" :match

      def _match(provider_piece, request_piece)
        # apply eliminations
        _provider_piece, _request_piece = Eliminator.new(provider_piece, request_piece).eliminate

        # features are matched if both pieces are empty
        return true if _provider_piece.is_a?(EmptyFeature) and _request_piece.is_a?(EmptyFeature)

        # feature are unmatched if peaces are not elminated
        return false if provider_piece == _provider_piece and request_piece == _request_piece

        # next
        return _match(_provider_piece, _request_piece)
      end
    end

    #
    # feature operations
    #

    class Eliminator
      OPERATIONS = [
        :eliminate_requisite_feature,
        :eliminate_requisite_feature_by_almighty_feature,
        :eliminate_blocking_feature,
        :eliminate_preferred_feature,
        :eliminate_possible_feature,
        :eliminate_almighty_feature
      ]

      def initialize(provider_piece, request_piece)
        @provider_piece = provider_piece
        @request_piece = request_piece
      end

      def eliminate
        OPERATIONS.inject([@provider_piece, @request_piece]) do |(ppiece, rpiece), elim|
          result, _ppiece, _rpiece = __send__(elim, ppiece, rpiece)
          result ? [_ppiece, _rpiece] : [ppiece, rpiece]
        end
      end

      # Eliminate a requisite feature from the request pieces. This is for the
      # case that requisite feature is satisfied by possible feature or
      # restrictive feature.
      #
      # Rule:
      # - (^X & Γ <- +X & Δ) -> Γ & Δ
      # - (!X & Γ <- +X & Δ) -> Γ & Δ
      def eliminate_requisite_feature(provider_piece, request_piece)
        ppieces = provider_piece.is_a?(CompoundFeature) ? provider_piece.pieces : [provider_piece]
        rpieces = request_piece.is_a?(CompoundFeature) ? request_piece.pieces : [request_piece]

        rpieces.each do |rpiece|
          # requisite feature is target
          next unless rpiece.kind_of?(RequisiteFeature)

          ppieces.each do |ppiece|
            next unless ppiece.kind_of?(PossibleFeature) || ppiece.kind_of?(RestrictiveFeature)
            next unless ppiece.name == rpiece.name

            # eliminate only if Γ dosen't include same symbol feature
            next if ppieces.any? {|piece| ppiece.name == piece.name && not(piece.kind_of?(ppiece.class))}

            # eliminate only if Δ dosen't include same symbol feature
            next if rpieces.any? {|piece| rpiece.name == piece.name && not(piece.kind_of?(rpiece.class))}

            # eliminate
            return true, rebuild_feature(ppieces - [ppiece]), rebuild_feature(rpieces - [rpiece])
          end
        end

        return false
      end

      # Eliminate request features by almighty feature.
      #
      # Rule:
      # - (** <- +X & Δ) -> (** <- Δ)
      def eliminate_requisite_feature_by_almighty_feature(provider_piece, request_piece)
        ppieces = provider_piece.is_a?(CompoundFeature) ? provider_piece.pieces : [provider_piece]
        rpieces = request_piece.is_a?(CompoundFeature) ? request_piece.pieces : [request_piece]

        rpieces.each do |rpiece|
          # requisite feature is target
          next unless rpiece.kind_of?(RequisiteFeature)

          ppieces.each do |ppiece|
            next unless ppiece.kind_of?(AlmightyFeature)

            # eliminate
            return true, provider_piece, rebuild_feature(rpieces - [rpiece])
          end
        end

        return false
      end

      # Elimiate a blocking feature.
      #
      # Rule:
      # - (Γ <- -X & Δ) -> Γ & Δ
      def eliminate_blocking_feature(provider_piece, request_piece)
        ppieces = provider_piece.is_a?(CompoundFeature) ? provider_piece.pieces : [provider_piece]
        rpieces = request_piece.is_a?(CompoundFeature) ? request_piece.pieces : [request_piece]

        rpieces.each do |rpiece|
          next unless rpiece.kind_of?(BlockingFeature)

          # eliminate only if Γ dosen't include almighty features
          next if ppieces.any? {|ppiece| ppiece.is_a?(AlmightyFeature)}

          # eliminate only if Γ dosen't include same name features
          next if ppieces.any? {|ppiece| ppiece.name == rpiece.name && not(ppiece.kind_of?(rpiece.class))}

          # eliminate only if Δ dosen't include same name features
          next if rpieces.any? {|piece| rpiece.name == piece.name && not(piece.kind_of?(rpiece.class))}

          # eliminate
          return true, provider_piece, rebuild_feature(rpieces - [rpiece])
        end

        return false
      end

      # Eliminate a preferred feature.
      #
      # Rule:
      # - (Γ <- ?X & Δ) -> (Γ <- Δ)
      def eliminate_preferred_feature(provider_piece, request_piece)
        ppieces = provider_piece.is_a?(CompoundFeature) ? provider_piece.pieces : [provider_piece]
        rpieces = request_piece.is_a?(CompoundFeature) ? request_piece.pieces : [request_piece]

        if rpieces.any? {|e| e.kind_of?(PreferredFeature)}
          _request = rebuild_feature(rpieces.reject {|rpiece| rpiece.kind_of?(PreferredFeature)})
          return true, provider_piece, _request
        end

        return false
      end

      # Eliminate a possible feature.
      #
      # Rule:
      # - (^X & Γ <- Δ) -> (Γ <- Δ)
      def eliminate_possible_feature(provider_piece, request_piece)
        ppieces = provider_piece.is_a?(CompoundFeature) ? provider_piece.pieces : [provider_piece]
        rpieces = request_piece.is_a?(CompoundFeature) ? request_piece.pieces : [request_piece]

        ppieces.each do |ppiece|
          next unless ppiece.kind_of?(PossibleFeature)

          # eliminate only if Γ dosen't include same symbol feature
          next if ppieces.any? {|piece| ppiece.name == piece.name && not(piece.kind_of?(ppiece.class))}

          # eliminate only if Δ dosen't include same symbol feature
          next if rpieces.any? {|rpiece| ppiece.name == rpiece.name && not(rpiece.kind_of?(ppiece.class))}

          # eliminate
          return true, rebuild_feature(ppieces - [ppiece]), request_piece
        end

        return false
      end

      # Eliminate almighty feature.
      #
      # Rule:
      # - (** <- *) -> (* <- *)
      # - (** <- **) -> (* <- *)
      def eliminate_almighty_feature(provider_piece, request_piece)
        pclass = provider_piece.class
        rclass = request_piece.class

        if pclass == AlmightyFeature and (rclass == AlmightyFeature or rclass == EmptyFeature)
          return true, EmptyFeature.new, EmptyFeature.new
        end

        return false
      end

      private

      def rebuild_feature(pieces)
        case pieces.size
        when 0
          EmptyFeature.new
        when 1
          pieces.first
        else
          CompoundFeature.new(pieces: pieces)
        end
      end
    end

    TypeFeature.instance_eval do
      # Build a compound feature.
      define_pione_method("&", [TypeFeature], TypeFeature) do |env, rec, other|
        rec.map2(other) do |rec_piece, other_piece|
          CompoundFeature.build(rec_piece, other_piece)
        end
      end

      # Return true if the request feature accepts the provider feature.
      define_pione_method("match", [TypeFeature], TypeBoolean) do |env, rec, other|
        raise ArgumentError.new(rec) if rec.feature_type == :request
        BooleanSequence.of(rec.match(other))
      end

      # Return string format of the feature.
      define_pione_method("as_string", [], TypeString) do |env, rec|
        PioneString.of(rec.textize)
      end
    end
  end
end
