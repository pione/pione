# -*- coding: utf-8 -*-
require 'pione/common'

module Pione
  module Feature

    # Expr is a super class for all feature expressions.
    class Expr
      def simplify
        return self
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
          elt.elements.each do |e|
            unless self.class::UNIFICATIONS.any?{|name| __send__(name, e)}
              @elements.add(e)
            end
          end
        else
          unless self.class::UNIFICATIONS.any?{|name| __send__(name, elt)}
            @elements.add(elt)
          end
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

      def ==(other)
        other.kind_of?(self.class) and @elements == other.elements
      end

      alias :eql? :==

      # Return hash value.
      def hash
        @left.hash + @right.hash
      end
    end

    class AndExpr < Connective
      UNIFICATIONS =
        [ :unify_redundant_feature,
          :summarize_or,
          :background_preferred_feature,
          :unify_by_restrictive_feature
        ]

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
            add(union_expr)
            add(AndExpr.new(*(target.elements - union).to_a))
            add(AndExpr.new(*(elt.elements - union).to_a))
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
          # +X | - X -> *
          if @elements.reject!{|e|
              e.symbol == elt.symbol && e.kind_of?(RequisiteExpr)
            }
            add(EmptyExpr.new)
            return true
          end
        when RequisiteExpr
          # -X | +X -> *
          if @elements.reject!{|e|
              e.symbol == elt.symbol && e.kind_of?(BlockingExpr)
            }
            add(EmptyExpr.new)
            return true
          end
        end
        return false
      end
    end

    class Sentence < Expr; end
  end
end
