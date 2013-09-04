module Pione
  module Lang
    class Context < StructX
      def eval!(env)
        eval(env)
      end
    end

    # StructuralContext is a basic context for all contexts.
    class StructuralContext < Context
      class << self
        # Return all accepted declaration types in the context.
        def acceptances
          @acceptances ||= []
        end

        # Trun the element to be accepted in the context.
        def accept(elt)
          acceptances << elt

          # define the accessor by snakecase
          define_method(elt.to_s.snake_case) do
            elements.select{|e| e.kind_of?(elt)}
          end
        end

        def inherited(subclass)
          acceptances.each {|acceptance| subclass.accept acceptance}
          members.each {|member_name| subclass.member(member_name, default: default_values[member_name])}
        end
      end

      member :elements, default: lambda { Array.new }
      forward :class, :acceptances

      # Initialize and validate the context.
      def initialize(*args)
        super(*args)
        raise ArgumentError.new(args) unless elements
        validate(acceptances)
      end

      # Validate that the element type is accepted or not. This validation
      # applies same criteria to conditional branches recursively.
      def validate(acceptances)
        elements.each do |elt|
          # check the type
          accepted = acceptances.any? {|type| type == :all or elt.kind_of?(type)}

          # raise a context error if the type is not accepted
          raise ContextError.new(elt, self) if not(accepted)

          # check for inner branches recursively
          if elt.kind_of?(ConditionalBranch)
            elt.validate(acceptances)
          end
        end
      end

      # Evaluete each element in the context. Pione permit declarations to be in
      # arbitray order, so the strategy of evaluation is try and error.
      def eval(env)
        try_to_eval(env, elements)
      end

      # Make trial loop for evaluation.
      def try_to_eval(env, elts)
        return if elts.empty?

        exception = nil
        next_elts = []

        # trial
        elts.each do |elt|
          begin
            elt.eval(env).tap {|res| next_elts << res if res.is_a?(Context)}
          rescue UnboundError => e
            exception = e
            next_elts << elt
          end
        end if elts

        # stop endless loop
        if elts == next_elts
          raise exception
        end

        # go next trial
        unless next_elts.empty?
          return try_to_eval(env, next_elts)
        end
      end

      # Return the position of first element in the context.
      def pos
        if elements.size > 0
          elements.first.pos
        end
      end

      def +(other)
        if self.class == other.class
          set(elements: elements + other.elements)
        else
          raise ContextError.new(other, self)
        end
      end
    end

    # ConditionalBranchContext is a free context for conditional branches.
    class ConditionalBranchContext < StructuralContext
      accept VariableBindingDeclaration
      accept PackageBindingDeclaration
      accept RuleBindingDeclaration
      accept InputDeclaration
      accept OutputDeclaration
      accept FeatureDeclaration
      accept ConstraintDeclaration
      accept AnnotationDeclaration
      accept ConstituentRuleDeclaration
      accept IfBranch
      accept CaseBranch
      accept ExprDeclaration
      accept FlowRuleDeclaration
      accept ActionRuleDeclaration
      accept EmptyRuleDeclaration
    end

    # ParamContext is a context for parameter block. This context takes special
    # interpretation of variable binding declaration.
    class ParamContext < StructuralContext
      accept VariableBindingDeclaration
      accept IfBranch
      accept CaseBranch
      accept ExprDeclaration

      member :type

      def eval(env)
        if elements.any? {|elt| elt.is_a?(VariableBindingDeclaration)}
          set(elements: elements.map {|elt| transform(elt)}).eval(env)
        else
          super
        end
      end

      # Trasform variable binding declarations into param declarations.
      def transform(declaration)
        if declaration.is_a?(VariableBindingDeclaration)
          ParamDeclaration.new(type, declaration.expr1, declaration.expr2)
        else
          declaration
        end
      end
    end

    # RuleConditionContext is a context for rule conditions.
    class RuleConditionContext < StructuralContext
      accept VariableBindingDeclaration
      accept InputDeclaration
      accept OutputDeclaration
      accept ParamDeclaration
      accept FeatureDeclaration
      accept ConstraintDeclaration
      accept AnnotationDeclaration
      accept IfBranch
      accept CaseBranch
      accept ExprDeclaration

      # Evaluate the rule condition context. Return a new definition of rule condition.
      def eval(env)
        RuleCondition.new.tap do |definition|
          env.temp(current_definition: definition) {|_env| super(_env)}
        end
      end
    end

    # FlowContext is a context for flow rule body.
    class FlowContext < StructuralContext
      accept VariableBindingDeclaration
      accept AnnotationDeclaration
      accept ConstituentRuleDeclaration
      accept IfBranch
      accept CaseBranch
      accept ExprDeclaration

      # Evaluate the flow context. Return a new definition of constituent rule set.
      def eval(env)
        ConstituentRuleSet.new.tap do |definition|
          env.temp(current_definition: definition) {|_env| super(_env)}
        end
      end
    end

    # PackageContext is a context for document toplevels.
    class PackageContext < StructuralContext
      accept VariableBindingDeclaration
      accept PackageBindingDeclaration
      accept RuleBindingDeclaration
      accept ParamDeclaration
      accept AnnotationDeclaration
      accept IfBranch
      accept CaseBranch
      accept ExprDeclaration
      accept ParamBlockDeclaration
      accept FlowRuleDeclaration
      accept ActionRuleDeclaration
      accept EmptyRuleDeclaration
    end

    class LiteralContext < Context
      include Util::Positionable
      member :string

      def eval(env)
        env.current_definition.content << string
      end
    end

    class ActionContext < LiteralContext
      # Evaluate the action context. Return a new action content.
      def eval(env)
        ActionContent.new.tap do |definition|
          env.temp(current_definition: definition) {|_env| super(_env)}
        end
      end
    end
  end
end
