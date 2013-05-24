# -*- coding: utf-8 -*-

module Pione::Model
  # Feature is selection system between task and task worker.
  module Feature
    class << self
      # Return feature conjunction.
      #
      # @param exprs [Array<Expr>]
      #   feature expression list
      # @return [Expr]
      #   conjuncted expression
      #
      # @example
      #   x = RequisiteExpr.new("X")
      #   y = RequisiteExpr.new("Y")
      #   Feature.and(x, y) #=> +X & +Y
      def and(*exprs)
        AndExpr.new(*exprs)
      end

      # Return feature disjunction.
      #
      # @param exprs [Array<Expr>]
      #   feature expression list
      # @return [Expr]
      #   disjuncted expression
      #
      # @example
      #   x = RequisiteExpr.new("X")
      #   y = RequisiteExpr.new("Y")
      #   Feature.or(x, y) #=> +X | +Y
      def or(*exprs)
        OrExpr.new(*exprs)
      end

      # Return empty feature.
      #
      # @return [Expr]
      #    empty feature
      def empty
        empty ||= EmptyFeature.new
      end

      # Return boundless feature.
      #
      # @return [Expr]
      #   boundless feature
      def boundless
        boundless ||= BoundlessFeature.new
      end
    end

    # Expr is a super class for all feature expressions.
    class Expr < Callable
      set_pione_model_type TypeFeature

      # Return simplified expression.
      #
      # @return [Expr]
      #   simplified expression
      def simplify
        return self
      end

      # Return true if the feature is empty.
      #
      # @return [Boolean]
      #   true if the feature is empty
      def empty?
        return false
      end

      # Return true if the other matches the feature.
      #
      # @return [Boolean]
      #   true if the other matches the feature
      def match(other)
        raise ArgumentError.new(other) unless other.kind_of?(Expr)
        Sentence.new(self, other).decide
      end
      alias :=== :match
    end

    # SpecialFeature is a class for empty feature and boundless feature.
    class SpecialFeature < Expr
      # @api private
      def textize
        symbol
      end

      # @api private
      def ==(other)
        other.kind_of?(self.class)
       end
      alias :eql? :==

      # @api private
      def hash
        true.hash
      end
    end

    # EmptyFeature is a class for empty feature that is one of special
    # features. This is written as '*', that means the worker has no specific
    # ability in provider expression and the task has no specific request in
    # request expression.
    class EmptyFeature < SpecialFeature
      # Return the symbol of empty feature.
      #
      # return [String]
      #   "*"
      def symbol
        "*"
      end

      # Return true because empty feature is empty.
      #
      # @return [Boolean]
      #   true
      def empty?
        true
      end

      # @api private
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
      # Return the symbol of bundless feature.
      #
      # return [String]
      #   "@"
      def symbol
        "@"
      end

      # @api private
      def ==(other)
        other.kind_of?(BoundlessFeature)
      end
    end

    # Operator is superclass of all operator classes.
    class Operator < Expr; end

    # UnaryOperator is a class for provider opeators and request operator.
    class UnaryOperator < Operator
      attr_reader :symbol

      # Return the operator symbol.
      #
      # @return [String]
      #   operator symbol
      # @example
      #   # requisite feature
      #   +
      # @example
      #   # blocking feature
      #   -
      # @example
      #   # preferred feature
      #   ?
      # @example
      #   # possible operator
      #   ^
      # @example
      #   # restrictive opeator
      #   !
      def self.operator
        @operator
      end

      # Create a new operator.
      #
      # @param [Symbol] symbol
      #   feature symbol
      def initialize(symbol)
        @symbol = symbol
        super()
      end

      # @api private
      def textize
        "%s%s" % [self.operator, @symbol]
      end

      # @api private
      def as_string
        self.class.operator + @symbol.to_s
      end

      # @api private
      def ==(other)
        other.kind_of?(self.class) and @symbol == other.symbol
      end
      alias :eql? :==

      # @api private
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
    #
    # @example
    #   !X
    class RestrictiveExpr < ProviderExpr
      @operator = "!"
    end

    # RequestOperator is a class for task's feature expression operators.
    class RequestExpr < UnaryOperator; end

    # Requisite Operator is a class for requisite feature expressions. Requisite
    # Feature are written like as "+X", these represent feature's requiste
    # ability.
    #
    # @example
    #   +X
    class RequisiteExpr < RequestExpr
      @operator = "+"
    end

    # BlockingExpr is a class for blocking feature expressions. Blocking Feature
    # are written like as "-X", these represent the ability that block to
    # execute the task.
    #
    # @example
    #   BlockingExpr.new("X") #=> -X
    class BlockingExpr < RequestExpr
      @operator = "-"
    end

    # PreferredExpr is a class for preferred feature expressions. Preferred
    # Feature are written like as "?X", these represent that task workers what
    # the feature have take the task.
    #
    # @example
    #   PreferredExpr.new("X") #=> ?X
    class PreferredExpr < RequestExpr
      @operator = "?"
    end

    # Connective is a superclass of AndExpr and OrExpr. This represents
    # connection of feature expressions.
    class Connective < Expr
      # @return [Set]
      #   feature expressions included in the connective
      attr_reader :elements

      # Create a new connective.
      #
      # @param elements [Array<Expr>]
      #   feature expressions
      def initialize(*elements)
        @elements = Set.new
        elements.each {|elt| add(elt) }
        super()
      end

      # Add the feature expression as elements of the connective and unify it.
      #
      # @param expr [Expr]
      #   feature element
      # @return [void]
      #
      # @example AND expression
      #   x = RequisiteExpr.new("X")
      #   y = RequisiteExpr.new("Y")
      #   AndExpr.new(x).add(y) #=> +X & +Y
      # @example OR expression
      #   x = RequisiteExpr.new("X")
      #   y = RequisiteExpr.new("Y")
      #   OrExpr.new(x, y).add(x) #=> +X | +Y
      def add(expr)
        if expr.kind_of?(self.class)
          expr.elements.each {|e| unify(e) }
        else
          unify(expr)
        end
      end

      # Delete the element from the connective set.
      #
      # @param elt [Expr]
      #   feature element
      # @return [void]
      def delete(elt)
        @elements.delete(elt)
        if @elements.empty?
          @elements.add(EmptyFeature.new)
        end
      end

      # Unify connective set by the element.
      #
      # @param [Expr] elt
      #   feature element
      # @return [void]
      def unify(elt)
        unless self.class::UNIFICATIONS.any?{|name| __send__(name, elt)}
          @elements.add(elt)
        end
      end

      # Simplify the connective by unifing and up-rising single element.
      #
      # @return [Expr]
      #   simplified feature
      #
      # @example
      #   AndExpr.new(RequisiteExpr.new("X")).simplify #=> +X
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

      # Return true if the connective set is empty.
      #
      # @return [Boolean]
      #   true if the connective set is empty
      def empty?
        return true if @elements.empty?
        return true if @elements == Set.new([Feature.empty])
        return false unless @elements.size == 1
        return @elements.first.empty?
      end

      # @api private
      def textize
        "#{self.class.name}(%s)" % @elements.map{|elt| elt.textize}.join(",")
      end

      # @api private
      def ==(other)
        return true if empty? and other.kind_of?(Expr) and other.empty?
        other.kind_of?(self.class) and @elements == other.elements
      end
      alias :eql? :"=="

      # @api private
      def hash
        @elements.hash
      end

      # Clone with cloning the elements set.
      #
      # @api private
      def clone
        obj = super
        elements = @elements.clone
        obj.instance_eval { @elements = elements }
        return obj
      end
    end

    # AndExpr represents conjunction of feature expressions.
    #
    # @example
    #   AndExpr.new(RequisiteExpr.new("X"), RequisiteExpr.new("Y")) #=> +X & +Y
    class AndExpr < Connective
      UNIFICATIONS =
        [ :unify_redundant_feature,
          :summarize_or,
          :background_preferred_feature,
          :unify_by_restrictive_feature
        ]

      module UnificationMethod
        # Unify redundant feature. This unification rule is described as
        # follows:
        #
        # - Γ & Γ -> Γ
        # - Δ & Δ -> Δ
        #
        # @param expr [Expr]
        #   feature expression
        #
        # @example
        #   x = RequisiteExpr.new("X")
        #   y = RequisiteExpr.new("Y")
        #   AndExpr.new(x,y).unify_redundant_feature(x) #=> true
        def unify_redundant_feature(expr)
          return @elements.include?(expr)
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

      # Make an expander for response test.
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

      # Choose a concrete expression that expand or-clause.
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

    # OrExpr represents disjunction of feature expressions.
    #
    # @example
    #   OrExpr.new(RequisiteExpr.new("X"), RequisiteExpr.new("Y")) #=> +X | +Y
    class OrExpr < Connective
      # unification list
      UNIFICATIONS =
        [ :unify_redundant_feature,
          :summarize_and,
          :foreground_preferred_feature,
          :unify_by_possible_feature,
          :neutralize
        ]

      # OrExpr's unification methods.
      module UnificationMethod
        # Return true if elements include the feature. This unification rule is
        # described as follows:
        #
        # - Γ | Γ -> Γ
        # - Δ | Δ -> Δ
        #
        # @param expr [Expr]
        #   feature expression
        #
        # @example
        #   x = RequisiteExpr.new("X")
        #   y = RequisiteExpr.new("Y")
        #   OrExpr.new(x, y).unify_redundant_feature(x) #=> true
        def unify_redundant_feature(expr)
          return @elements.include?(expr)
        end

        # Return true if the expression is summarized by AND connective. This
        # rule is described as follows:
        #
        # - (Γ1 & Γ2) | (Γ1 & Γ3) -> Γ1 & (Γ2 | Γ3)
        # - Γ1 | (Γ1 & Γ3) -> Γ1
        # - (Γ1 & Γ2) | Γ1 -> Γ1
        def summarize_and(elt)
          if elt.kind_of?(AndExpr)
            # (Γ1 & Γ2) | (Γ1 & Γ3) -> Γ1 & (Γ2 | Γ3)
            if target = @elements.find {|e|
                e.kind_of?(AndExpr) && not((e.elements & elt.elements).empty?)
              }
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

      # Make an expander for response test.
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
        super()
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

  #   class FeatureSequence < Sequence
  #     set_pione_model_type TypeFeature
  #     set_element_class Feature::Expr
  #   end
  end

  TypeFeature.instance_eval do
    define_pione_method("==", [TypeFeature], TypeBoolean) do |vtable, rec, other|
      PioneBoolean.new(rec == other).to_seq
    end

    define_pione_method("!=", [TypeFeature], TypeBoolean) do |vtable, rec, other|
      PioneBoolean.not(rec.call_pione_method(vtable, "==", other)).to_seq
    end

    define_pione_method("as_string", [], TypeString) do |vtable, rec|
      PioneString.new(rec.as_string).to_seq
    end

    define_pione_method("str", [], TypeString) do |vtable, rec|
      rec.call_pione_method(vtable, "as_string")
    end
  end
end
