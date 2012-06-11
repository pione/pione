# -*- coding: utf-8 -*-
require 'pione/common'

module Pione
  module Feature

    # Expr is a super class for all feature expressions.
    class Expr
      def simplify
        return self
      end

      def expand
        return self
      end

      def empty?
        return false
      end

      def match(other)
        raise NotImplementedError
      end

      alias :=== :match
    end

    # Symbol represents feature symbols.
    class Symbol < Expr
      attr_reader :identifier

      def initialize(identifier)
        @identifier = identifier
      end

      def ==(other)
        other.kind_of?(Symbol) and @identifier == other.identifier
      end

      alias :eql? :==

      # Return hash value.
      def hash
        @identifier.hash
      end
    end

    class SpecialFeature < Expr
      def ==(other)
        other.kind_of?(self.class)
      end

      alias :eql? :==

      # Return hash value.
      def hash
        true.hash
      end
    end

    # EmptyFeature is a class for empty feature that is one of special
    # features. This is written as '*', that means the worker has no specific
    # ability in provider expression and the task has no specific request in
    # request expression.
    class EmptyFeature < SpecialFeature; end

    # BoundlessFeature is a class for whole feature that is one of special
    # features. This is written as '@', that means the worker has boundless
    # ability in provider expression and the task has boundless ability request
    # in request expression.
    class BoundlessFeature < SpecialFeature; end

    # Operator
    class Operator < Expr; end

    # UnaryOperator is a class for provider opeators and request operator
    class UnaryOperator < Operator
      attr_reader :symbol

      def initialize(symbol)
        @symbol = symbol
      end

      def ==(other)
        other.kind_of?(self.class) and @symbol == other.symbol
      end

      alias :eql? :==

      # Return hash value.
      def hash
        @symbol.hash
      end
    end

    # ProviderOperator is a class for provider operators.
    class ProviderExpr < UnaryOperator; end

    # PossibleOperator is a class for possible feature expressions. Possible
    # feature are written like as "^X", these represent feature's possible
    # ability.
    class PossibleExpr < ProviderExpr; end

    # RestrictiveExpr is a class for restrictive feature expression.
    class RestrictiveExpr < ProviderExpr; end

    # RequestOperator is a class for task's feature expression operators.
    class RequestExpr < UnaryOperator; end

    # Requisite Operator is a class for requisite feature expressions. Requisite
    # Feature are written like as "+X", these represent feature's requiste
    # ability.
    class RequisiteExpr < RequestExpr; end

    # 
    class BlockingExpr < RequestExpr; end

    class PreferredExpr < RequestExpr; end

    class Connective < Expr
      attr_reader :elements

      def initialize(*elements)
        @elements = Set.new
        elements.each {|elt| add(elt) }
      end

      def add(elt)
        if elt.kind_of?(self.class)
          elt.elements.each {|e| unify(e) }
        else
          unify(elt)
        end
      end

      def delete(elt)
        @elements.delete(elt)
        if @elements.empty?
          @elements.add(EmptyFeature.new)
        end
      end

      def unify(elt)
        unless self.class::UNIFICATIONS.any?{|name| __send__(name, elt)}
          @elements.add(elt)
        end
      end

      def simplify
        if @elements.size == 1
          return @elements.first.simplify
        else
          elements = @elements.map{|e| e.simplify}
          @elements.clear
          elements.each {|e| add(e)}
          return self
        end
      end

      def empty?
        return false unless @elements.size == 1
        return @elements.first.empty?
      end

      def ==(other)
        other.kind_of?(self.class) and @elements == other.elements
      end

      alias :eql? :==

      # Return hash value.
      def hash
        @elements.hash
      end

      # Clone with cloning the elements set.
      def clone
        obj = super
        obj.elements = @elements.clone
        return obj
      end
    end

    class AndExpr < Connective
      UNIFICATIONS =
        [ :unify_redundant_feature,
          :summarize_or,
          :background_preferred_feature,
          :unify_by_restrictive_feature
        ]

      def expander
        elements = @elements.map do |elt|
          if elt.kind_of?(OrExpr)
            elements << elt.expander
          else
            elements << elt
          end
        end
        return Enumerator.new {|y| make_list(y, elements, [], nil, 0) }
      end

      def make_list(y, orig, list, fiber, i)
        if orig.size == i
          y << as_list(list)
          fiber.resume
        else
          if orig[i].kind_of?(Enumerator)
            _fiber = Fiber.new do
              begin
                make_list(y, orig, [orig[i].next, list], _fiber, i+1)
                Fiber.yield
              rescue StopIteration
                fiber ? fiber.resume : raise StopIteration
              end
            end
            loop { _fiber.resume }
          else
            make_list(y, orig, [orig[i], list], cc, i+1)
          end
        end
      end

      def as_list(input)
        if input == []
          return []
        else
          as_list(input[1]) << input[0]
        end
      end

      private

      def unify_redundant_feature(elt)
        # Γ & Γ -> Γ
        # Δ & Δ -> Δ
        return @elements.include?(elt)
      end

      def summarize_or(elt)
        if elt.kind_of?(OrExpr)
          if target = @elements.find {|e|
              if e.kind_of?(OrExpr)
                not((e.elements & elt.elements).empty?)
              end
            }
            # (Γ1 | Γ2) & (Γ1 | Γ3) -> Γ1 | (Γ2 & Γ3)
            @elements.delete(target)
            union = target.elements & elt.elements
            union_expr = if union.length > 1
                           OrExpr.new(*union.to_a)
                         else
                           union.to_a.first
                         end
            add(OrExpr.new(union_expr,
                           AndExpr.new(OrExpr.new(*(target.elements - union).to_a),
                                       OrExpr.new(*(elt.elements - union).to_a))))
            return true
          else
            # Γ1 & (Γ1 | Γ3) -> Γ1
            return not((@elements & elt.elements).empty?)
          end
        else
          # (Γ1 | Γ2) & Γ1 -> Γ1
          if @elements.reject!{|e| e == elt }
            add(elt)
            return true
          end
        end
        return false
      end

      def background_preferred_feature(elt)
        case elt
        when PreferredExpr
          # !X & ?X -> !X
          # ^X & ?X -> ^X
          return @elements.any? {|e|
            e.symbol == elt.symbol &&
              (e.kind_of?(RequisiteExpr) || e.kind_of?(BlockingExpr))
          }
        when RequisiteExpr, BlockingExpr
          # ?X & !X -> !X
          # ?X & ^X -> ^X
          if @elements.reject! {|e|
              if e.kind_of?(PreferredExpr)
                e.symbol == elt.symbol
              end
            }
            add(elt)
            return true
          end
        end
        return false
      end

      def unify_by_restrictive_feature(elt)
        case elt
        when RestrictiveExpr
          # ^X & !X -> !X
          if @elements.reject! {|e|
              if e.kind_of?(PossibleExpr)
                e.symbol == elt.symbol
              end
            }
            add(elt)
            return true
          end
        when PossibleExpr
          # !X & ^X -> !X
          return @elements.any? {|e|
            if e.kind_of?(RestrictiveExpr)
              e.symbol == elt.symbol
            end
          }
        end
        return false
      end
    end

    class OrExpr < Connective
      UNIFICATIONS =
        [ :unify_redundant_feature,
          :summarize_and,
          :foreground_preferred_feature,
          :unify_by_possible_feature,
          :neutralize
        ]

      def expander
        Enumerator.new do |y|
          @elements.each do |elt|
            if elt.kind_of?(AndExpr)
              elt.expander.each {|e| y << e }
            else
              y << elt
            end
          end
        end
      end

      private

      def unify_redundant_feature(elt)
        # Γ | Γ -> Γ
        # Δ | Δ -> Δ
        return @elements.include?(elt)
      end

      def summarize_and(elt)
        if elt.kind_of?(AndExpr)
          if target = @elements.find {|e|
              e.kind_of?(AndExpr) && not((e.elements & elt.elements).empty?)
            }
            # (Γ1 & Γ2) | (Γ1 & Γ3) -> Γ1 & (Γ2 | Γ3)
            @elements.delete(target)
            union = target.elements & elt.elements
            union_expr = if union.length > 1
                           AndExpr.new(*union.to_a)
                         else
                           union.to_a.first
                         end
            add(AndExpr.new(union_expr,
                           OrExpr.new(AndExpr.new(*(target.elements - union).to_a),
                                      AndExpr.new(*(elt.elements - union).to_a))))
            return true
          else
            # Γ1 | (Γ1 & Γ3) -> Γ1
            # return not((@elements & elt.elements).empty?)
          end
        else
          # (Γ1 & Γ2) | Γ1 -> Γ1
          # if @elements.reject!{|e| e == elt }
          #   add(elt)
          #   return true
          # end
        end
        return false
      end

      def foreground_preferred_feature(elt)
        case elt
        when PreferredExpr
          # !X | ?X -> ?X
          # ^X | ?X -> ?X
          if @elements.reject! {|e|
            e.symbol == elt.symbol &&
              (e.kind_of?(RequisiteExpr) || e.kind_of?(BlockingExpr))
            }
            add(elt)
            return true
          end
        when RequisiteExpr, BlockingExpr
          # ?X | !X -> ?X
          # ?X | ^X -> ?X
          return @elements.any? {|e|
            e.symbol == elt.symbol && e.kind_of?(PreferredExpr)
          }
        end
        return false
      end

      def unify_by_possible_feature(elt)
        case elt
        when PossibleExpr
          # !X | ^X -> ^X
          if @elements.reject! {|e|
              e.symbol == elt.symbol && e.kind_of?(RestrictiveExpr)
            }
            add(elt)
            return true
          end
        when RestrictiveExpr
          # ^X | !X -> ^X
          return @elements.any? {|e|
            e.symbol == elt.symbol && e.kind_of?(PossibleExpr)
          }
        end
        return false
      end

      def neutralize(elt)
        case elt
        when BlockingExpr
          # +X | -X -> *
          if @elements.reject!{|e|
              e.symbol == elt.symbol && e.kind_of?(RequisiteExpr)
            }
            add(EmptyFeature.new)
            return true
          end
        when RequisiteExpr
          # -X | +X -> *
          if @elements.reject!{|e|
              e.symbol == elt.symbol && e.kind_of?(BlockingExpr)
            }
            add(EmptyFeature.new)
            return true
          end
        end
        return false
      end
    end

    class Sentence < Expr
      def initialize(provider, request)
        @provider = AndExpr.new(provider.simplify)
        @request = AndExpr.new(request.simplify)
      end

      def decide
        @provider.expander.each do |provider|
          @request.expander.each do |request|
            return true if match(provider, request)
          end
        end
        return false
      end

      ELIMINATIONS =
        [ :eliminate_requisite_feature,
          :eliminate_blocking_feature,
          :eliminate_preferred_feature,
          :eliminate_empty_feature,
          :eliminate_possible_feature
        ]

      def match(provider, request)
        _provider = provider
        _request = request
        ELIMINATIONS.each do |elim|
          _provider, _request = __send__(elim, provider, request)
          break if _provider and _request
        end
        if _provider.simplify.empty? && _request.simplify.empty?
          return true
        else
          if provider == _provider and request == _request
            return false
          else
            return match(_provider, _request)
          end
        end
      end

      def eliminate_requisite_feature(provider, request)
        # (^X & Γ <- +X & Δ) -> Γ & Δ
        # (!X & Γ <- +X & Δ) -> Γ & Δ
        request.elements.each do |r|
          next unless p.kind_of?(RequisiteExpr)
          provider.elements.each do |p|
            next unless p.symbol == r.symbol
            next unless r.kind_of?(PossibleExpr) || r.kind_of?(RestrictiveExpr)
            # eliminate only if Γ dosen't include same symbol feature
            next if provider.elements.any?{|e|
              p.symbol == e.symbol && not(e.kind_of?(p.class))
            }
            # eliminate only if Δ dosen't include same symbol feature
            next if request.elements.any?{|e|
              r.symbol == e.symbol && not(e.kind_of?(r.class))
            }
            # eliminate
            _provider = provider.clone.tap{|x| x.delete(p)}
            _request = request.clone.tap{|x| x.delete(r)}
            return _provider, _request
          end
        end
      end

      def eliminate_blocking_feature(provider, request)
        # (Γ <- -X & Δ) -> Γ & Δ
        request.elements.each do |r|
          next unless p.kind_of?(BlockingExpr)
          provider.elements.each do |p|
            next unless p.symbol == r.symbol
            next unless r.kind_of?(PossibleExpr) || r.kind_of?(RestrictiveExpr)
            # eliminate only if Γ dosen't include same symbol feature
            next if request.elements.any?{|e|
              r.symbol == e.symbol && not(e.kind_of?(r.class))
            }
            # eliminate only if Δ dosen't include same symbol feature
            next if provider.elements.any?{|e|
              p.symbol == e.symbol && not(e.kind_of?(p.class))
            }
            # eliminate
            _provider = provider.clone.tap{|x| x.delete(p)}
            _request = request.clone.tap{|x| x.delete(r)}
            return _provider, _request
          end
        end
      end

      def eliminate_preferred_feature(provider, request)
        # (Γ <- ?X & Δ) -> (Γ <- Δ)
        if request.elements.any? {|e| e.kind_of?(PreferredExpr)}
          _request = request.clone.tap do |x|
            x.reject! {|e| e.kind_of?(PreferredExpr)}
          end
          return provider, _request
        end
      end

      def eliminate_empty_feature(provider, request)
        # ((* | Γ1) & Γ2 <- *) -> (Γ1 <- *)
        return if request.empty?
        provider.elements.each do |elt|
          next unless elt.kind_of?(OrExpr)
          if request.elements.include?(EmptyFeature.new)
            _provider = provider.clone.tap{|x| x.delete(elt)}
            return _provider, request
          end
        end
      end

      def eliminate_possible_feature(provider, request)
        # (^X & Γ <- Δ) -> (Γ <- Δ)
        provider.elements.each do |p|
          next unless p.kind_of?(PossibleExpr)
          # eliminate only if Γ dosen't include same symbol feature
          next if provider.elements.any?{|e|
            p.symbol == e.symbol && not(e.kind_of?(p.class))
          }
          # eliminate only if Δ dosen't include same symbol feature
          next if request.elements.any?{|e|
            r.symbol == e.symbol && not(e.kind_of?(r.class))
          }
          # eliminate
          _provider = provider.clone.tap{|x| x.delete(r)}
          return _provider, request
        end
      end
    end
  end
end
