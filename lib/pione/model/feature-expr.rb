# -*- coding: utf-8 -*-
require 'pione/common'

module Pione::Model
  module Feature
    def self.and(*exprs)
      AndExpr.new(*exprs)
    end

    def self.or(*exprs)
      OrExpr.new(*exprs)
    end

    def self.empty
      EmptyFeature.new
    end

    def self.boundless
      BoundlessFeature.new
    end

    # Expr is a super class for all feature expressions.
    class Expr < PioneModelObject
      def pione_model_type
        TypeFeature
      end

      def simplify
        return self
      end

      def empty?
        return false
      end

      def match(other)
        raise ArgumentError.new(other) unless other.kind_of?(Expr)
        Sentence.new(self, other).decide
      end

      alias :=== :match
    end

    # SpecialFeature is a class for empty feature and boundless feature.
    class SpecialFeature < Expr
      def task_id_string
        "Feature::SpecialFeature<#{symbol}>"
      end

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
    class EmptyFeature < SpecialFeature
      def symbol
        "*"
      end

      def empty?
        true
      end

      def ==(other)
        return false unless other.kind_of?(Expr)
        other.empty?
      end
    end

    # BoundlessFeature is a class for whole feature that is one of special
    # features. This is written as '@', that means the worker has boundless
    # ability in provider expression and the task has boundless ability request
    # in request expression.
    class BoundlessFeature < SpecialFeature
      def symbol
        "@"
      end
    end

    # Operator
    class Operator < Expr; end

    # UnaryOperator is a class for provider opeators and request operator
    class UnaryOperator < Operator
      attr_reader :symbol

      def self.operator
        @operator
      end

      def initialize(symbol)
        @symbol = symbol
      end

      def task_id_string
        "Feature::UnaryOperator<#{self.operator},#{@symbol}>"
      end

      def as_string
        self.class.operator + @symbol.to_s
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
    class PossibleExpr < ProviderExpr
      @operator = "^"
    end

    # RestrictiveExpr is a class for restrictive feature expression.
    class RestrictiveExpr < ProviderExpr
      @operator = "!"
    end

    # RequestOperator is a class for task's feature expression operators.
    class RequestExpr < UnaryOperator; end

    # Requisite Operator is a class for requisite feature expressions. Requisite
    # Feature are written like as "+X", these represent feature's requiste
    # ability.
    class RequisiteExpr < RequestExpr
      @operator = "+"
    end

    # BlockingExpr is a class for blocking feature expressions. Blocking Feature
    # are written like as "-X", these represent the ability that block to
    # execute the task.
    class BlockingExpr < RequestExpr
      @operator = "-"
    end

    class PreferredExpr < RequestExpr
      @operator = "?"
    end

    class Connective < Expr
      attr_reader :elements

      # Creates a new connective.
      def initialize(*elements)
        @elements = Set.new
        elements.each {|elt| add(elt) }
      end

      # Adds the element from the connective set and unifies by it.
      def add(elt)
        if elt.kind_of?(self.class)
          elt.elements.each {|e| unify(e) }
        else
          unify(elt)
        end
      end

      # Deletes the element from the connective set.
      def delete(elt)
        @elements.delete(elt)
        if @elements.empty?
          @elements.add(EmptyFeature.new)
        end
      end

      # Unifies connective set by the element.
      def unify(elt)
        unless self.class::UNIFICATIONS.any?{|name| __send__(name, elt)}
          @elements.add(elt)
        end
      end

      # Simplifies the connective by unifing and up-rising single element.
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

      # Returns true if the connective set is empty.
      def empty?
        return true if @elements.empty?
        return true if @elements == Set.new([Feature.empty])
        return false unless @elements.size == 1
        return @elements.first.empty?
      end

      def task_id_string
        "Feature::Connective<#{self.class.name},[%s]>" % [
          @elements.map{|elt| elt.task_id_string}.join(",")
        ]
      end

      def ==(other)
        return true if empty? and other.kind_of?(Expr) and other.empty?
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
        elements = @elements.clone
        obj.instance_eval { @elements = elements }
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

      module UnificationMethod
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
              add(
                OrExpr.new(
                  union_expr,
                  AndExpr.new(
                    OrExpr.new(*(target.elements - union).to_a),
                    OrExpr.new(*(elt.elements - union).to_a)
                  )
                )
              )
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

      include UnificationMethod

      # Makes an expander for response test.
      def expander
        # convert or-clause into expander
        elements = @elements.map do |elt|
          elt.kind_of?(OrExpr) ?  elt.expander : elt
        end
        # return an enumerator
        return Enumerator.new {|y| choose_concrete_expr(y, elements, [], nil, 0) }
      end

      private

      require 'fiber'

      # Chooses a concrete expression that expand or-clause.
      def choose_concrete_expr(y, orig, list, fiber, i)
        if orig.size == i
          # when reach the terminateion of elements, yield a concrete expression
          y << AndExpr.new(*convert_cons_list_into_array(list))
        else
          # or-clause
          if orig[i].kind_of?(Enumerator)
            # create a new fiber
            _fiber = Fiber.new do
              loop do
                # rewind unreached enumerators
                orig.each_with_index do |e, ii|
                  e.rewind if ii > i && e.kind_of?(Enumerator)
                end
                # choose next
                choose_concrete_expr(y, orig, [orig[i].next, list], _fiber, i+1)
                # retrun fiber loop
                Fiber.yield
              end
            end
            # fiber loop
            begin
              _fiber.transfer while true
            rescue FiberError => e
              fiber.transfer if fiber
            end
          else
            # other elements
            choose_concrete_expr(y, orig, [orig[i], list], fiber, i+1)
          end
        end
      end

      # Returns an array by converting from cons list.
      def convert_cons_list_into_array(input)
        input == [] ? [] : convert_cons_list_into_array(input[1]) << input.first
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

      module UnificationMethod
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

      include UnificationMethod

      # Makes an expander for response test.
      def expander
        Enumerator.new do |y|
          @elements.each do |elt|
            elt.kind_of?(AndExpr) ? elt.expander.each {|e| y << e } : y << elt
          end
        end
      end
    end

    class Sentence < Expr
      ELIMINATIONS =
        [ :eliminate_requisite_feature,
          :eliminate_blocking_feature,
          :eliminate_preferred_feature,
          :eliminate_or_clause_including_empty_feature,
          :eliminate_possible_feature
        ]

      module EliminationMethod
        def eliminate_requisite_feature(provider, request)
          # (^X & Γ <- +X & Δ) -> Γ & Δ
          # (!X & Γ <- +X & Δ) -> Γ & Δ
          request.elements.each do |r|
            next unless r.kind_of?(RequisiteExpr)
            provider.elements.each do |p|
              next unless p.symbol == r.symbol
              next unless p.kind_of?(PossibleExpr) || p.kind_of?(RestrictiveExpr)
              # eliminate only if Γ dosen't include same symbol feature
              next if provider.elements.any? {|e|
                p.symbol == e.symbol && not(e.kind_of?(p.class))
              }
              # eliminate only if Δ dosen't include same symbol feature
              next if request.elements.any? {|e|
                r.symbol == e.symbol && not(e.kind_of?(r.class))
              }
              # eliminate
              _provider = provider.clone.tap{|x| x.delete(p)}
              _request = request.clone.tap{|x| x.delete(r)}
              return true, _provider, _request
            end
          end
          return false
        end
        module_function :eliminate_requisite_feature

        def eliminate_blocking_feature(provider, request)
          # (Γ <- -X & Δ) -> Γ & Δ
          request.elements.each do |r|
            next unless r.kind_of?(BlockingExpr)
            # eliminate only if Γ dosen't include same symbol feature
            next if request.elements.any? {|e|
              r.symbol == e.symbol && not(e.kind_of?(r.class))
            }
            # eliminate only if Δ dosen't include same symbol feature
            next if provider.elements.any? {|e|
              r.symbol == e.symbol && not(e.kind_of?(p.class))
            }
            # eliminate
            _request = request.clone.tap{|x| x.delete(r)}
            return true, provider, _request
          end
          return false
        end
        module_function :eliminate_blocking_feature

        def eliminate_preferred_feature(provider, request)
          # (Γ <- ?X & Δ) -> (Γ <- Δ)
          if request.elements.any? {|e| e.kind_of?(PreferredExpr)}
            _request = request.clone.tap do |x|
              x.elements.reject! {|e| e.kind_of?(PreferredExpr)}
            end
            return true, provider, _request
          end
          return false
        end
        module_function :eliminate_preferred_feature

        def eliminate_or_clause_including_empty_feature(provider, request)
          # ((* | Γ1) & Γ2 <- *) -> (Γ2 <- *)
          return false unless request.empty?
          provider.elements.each do |elt|
            next unless elt.kind_of?(OrExpr)
            next unless elt.elements.include?(EmptyFeature.new)
            _provider = provider.clone.tap{|x| x.delete(elt)}
            return true, _provider, request
          end
          return false
        end
        module_function :eliminate_or_clause_including_empty_feature

        def eliminate_possible_feature(provider, request)
          # (^X & Γ <- Δ) -> (Γ <- Δ)
          provider.elements.each do |p|
            next unless p.kind_of?(PossibleExpr)
            # eliminate only if Γ dosen't include same symbol feature
            next if provider.elements.any? {|e|
              p.symbol == e.symbol && not(e.kind_of?(p.class))
            }
            # eliminate only if Δ dosen't include same symbol feature
            next if request.elements.any? {|e|
              p.symbol == e.symbol && not(e.kind_of?(p.class))
            }
            # eliminate
            _provider = provider.clone.tap{|x| x.delete(p)}
            return true, _provider, request
          end
          return false
        end
        module_function :eliminate_possible_feature
      end

      include EliminationMethod

      def initialize(provider, request)
        @provider = AndExpr.new(provider.simplify)
        @request = AndExpr.new(request.simplify)
      end

      # Return true if the provider expression can respond to the request.
      def decide
        result = false
        begin
          @provider.expander.each do |provider|
            @request.expander.each do |request|
              if match(provider, request)
                result = true
                raise StopIteration
              end
            end
          end
        rescue StopIteration
        end
        return result
      end

      private

      def match(provider, request)
        _provider, _request = provider, request
        ELIMINATIONS.each do |elim|
          result, new_provider, new_request = __send__(elim, provider, request)
          if result
            _provider = new_provider
            _request = new_request
            break
          end
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
    end
  end

  TypeFeature.instance_eval do
    define_pione_method("==", [TypeFeature], TypeBoolean) do |rec, other|
      PioneBoolean.new(rec == other)
    end

    define_pione_method("!=", [TypeFeature], TypeBoolean) do |rec, other|
      PioneBoolean.not(rec.call_pione_method("==", other))
    end

    define_pione_method("as_string", [], TypeString) do |rec|
      PioneString.new(rec.as_string)
    end
  end
end
