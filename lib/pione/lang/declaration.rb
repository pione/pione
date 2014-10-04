module Pione
  module Lang
    # Declaration is a base class for all declarations.
    class Declaration < StructX
      include Util::Positionable
      immutable true

      class << self
        def inherited(cls)
          members.each {|member_name| subclass.member(member_name, default: default_values[member_name])}
          immutable true
        end
      end

      def eval!(env)
        eval(env)
      end

      private

      # Get reference object. If it has no package id, set current package id in
      # the environment.
      def get_reference(env, name, expected)
        # evaluate the name expression if it has unexpected type
        # e.g. "$p.var($x) := 1"
        unless name.is_a?(expected)
          name = name.eval(env)

          # raise error if it has unexpected type
          unless name.is_a?(expected)
            raise StructuralError.new(expected, name.pos)
          end
        end

        # set current package id if it has no package id
        if name.is_a?(Sequence)
          name.map {|piece| piece.package_id ? piece : piece.set(package_id: env.current_package_id)}
        else
          name.package_id ? name : name.set(package_id: env.current_package_id)
        end
      end

      # Get the package id.
      def get_package_id(env, name)
        if package_id = name.package_id
          # get package id from the name
          return package_id
        else
          # or current package id in the environment
          return env.current_package_id
        end
      end
    end

    # VariableBindingDeclaration is a declaration for binding variable to expression.
    class VariableBindingDeclaration < Declaration
      member :expr1 # variable name
      member :expr2 # bound expression

      # Update variable table in the environment with the variable and bound
      # expression. We expect +expr1+ is a variable or variable generating
      # expression.
      def eval(env)
        var = get_reference(env, expr1, Variable)
        val = expr2

        # update variable table
        env.variable_set(var, val)
      end
    end

    # PackageBindingDeclaration is a declaration for package binding sentences.
    class PackageBindingDeclaration < Declaration
      member :expr1 # variable name
      member :expr2 # expression for generating new package

      # Update variable table and package table.
      def eval(env)
        # variable name
        var = get_reference(env, expr1, Variable)

        # check the parent package
        parent_package = expr2.eval(env)

        # evaluate expr2 and get new package instance
        child_pieces = parent_package.pieces.map do |parent_piece|
          # definition of parent package
          parent_definition = env.package_get(parent_piece)
          # generate new id
          child_id = Util::PackageID.generate(env, parent_piece.name)
          # validate parameter set
          parent_piece.param.pieces.each do |param_piece|
            param_piece.table.keys do |key|
              unless parent_definition.param_definition.has_key?(key.name)
                raise ParamError.new(key.name, parent_piece.package_id)
              end
            end
          end
          # update package table
          definition = PackageDefinition.new(
            package_id: child_id,
            parent_ids: [parent_piece.package_id],
            param_definition: parent_definition.param_definition,
            param: parent_definition.param.merge(parent_piece.param)
          )
          # create child piece
          child_piece = parent_piece.set(package_id: child_id, parent_ids: [parent_piece.package_id])
          # register the child to package table
          env.package_set(child_piece, definition)
          # result
          child_piece
        end
        child_package = PackageExprSequence.of(*child_pieces)

        # update variable table with the result
        VariableBindingDeclaration.new(var, child_package).eval(env)
      end
    end

    # ParamDeclaration is a declaration thae the parameter is neeeded.
    class ParamDeclaration < Declaration
      member :type  # basic/advanced
      member :expr1 # variable name
      member :expr2 # default expression

      def set_type(new_type)
        set(type: new_type)
      end

      # Add the parameter in current rule definition.
      def eval(env)
        # get variable
        var = get_reference(env, expr1, Variable)

        # we don't permit to declare parameters of other packages
        if not(var.package_id.nil?) and var.package_id != env.current_package_id
          raise ParamDeclarationError.new(self)
        end

        # get the value(don't evaluate in this time)
        default_val = expr2

        begin
          env.variable_get(var)
        rescue UnboundError
          # bind default value
          env.variable_set(var, default_val)
        end

        param = ParameterDefinition.new(type, var.name, default_val)

        # select target definition
        definition = nil
        if env.current_definition
          # in rule definition context
          definition = env.current_definition
        else
          # in package context
          definition = env.package_get(PackageExpr.new(package_id: var.package_id))
        end

        if definition.param_definition[var.name]
          raise RebindError.new(var)
        else
          definition.param_definition[var.name] = param
        end
      end
    end

    # RuleBindingDeclaration is a declaration for rule binding stentences.
    class RuleBindingDeclaration < Declaration
      member :expr1 # new rule name
      member :expr2 # referent

      # Update rule table with the rule name and reference definition.
      # e.g. "rule A := B"
      def eval(env)
        # rule name
        refs = get_reference(env, expr1, RuleExprSequence)

        refs.pieces.each do |ref|
          referents = expr2.eval!(env)
          referents.pieces.each do |referent|
            # merge param sets
            definition = env.rule_get_value(referent)
            param_sets = definition.param_sets.merge(referent.param_sets)
            _referent = referent.set(param_sets: param_sets)

            # update rule table
            env.rule_set(ref, _referent)
          end
        end
      end
    end

    # ConstituentRuleDeclaration is a declaration for constituent rule sentences.
    class ConstituentRuleDeclaration < Declaration
      member :expr

      # Append the constituent rule to the current definition.
      def eval(env)
        env.current_definition.rules += expr.eval!(env)
      end
    end

    # InputDeclaration is a declaration for input condition sentences.
    class InputDeclaration < Declaration
      member :expr

      # Append the input condition to the current definition.
      def eval(env)
        env.current_definition.inputs << expr
      end
    end

    # OutputDeclaration is a declaration for output condition sentences.
    class OutputDeclaration < Declaration
      member :expr

      # Append the output condition to the current definition.
      def eval(env)
        env.current_definition.outputs << expr
      end
    end

    class FeatureDeclaration < Declaration
      member :expr

      def eval(env)
        env.current_definition.features << expr
      end
    end

    class ConstraintDeclaration < Declaration
      member :expr

      def eval(env)
        env.current_definition.constraints << expr
      end
    end

    class AnnotationDeclaration < Declaration
      member :expr

      def eval(env)
        env.current_definition.annotations << expr.eval(env)
      end
    end

    class ExprDeclaration < Declaration
      member :expr

      # Return evaluation result of the value.
      def eval(env)
        expr.eval(env)
      end
    end

    class ParamBlockDeclaration < Declaration
      member :type
      member :context

      def eval(env)
        context.eval(env)
      end
    end

    class RuleDeclaration < Declaration; end

    class FlowRuleDeclaration < RuleDeclaration
      member :expr                   # rule name
      member :rule_condition_context # rule condition context
      member :flow_context           # flow context

      def eval(env)
        rules = get_reference(env, expr, RuleExprSequence)
        rules.pieces.each do |piece|
          ref = piece.set(package_id: get_package_id(env, piece))

          definition = FlowRuleDefinition.new(
            rule_condition_context: rule_condition_context,
            flow_context: flow_context
          )

          env.rule_set(ref, definition)
        end
      end
    end

    class ActionRuleDeclaration < RuleDeclaration
      member :expr              # rule name
      member :condition_context # rule condition context
      member :action_context    # action context

      def eval(env)
        rules = get_reference(env, expr, RuleExprSequence)
        rules.pieces.each do |piece|
          ref = piece.set(package_id: get_package_id(env, piece))

          definition = ActionRuleDefinition.new(
            rule_condition_context: condition_context,
            action_context: action_context
          )

          env.rule_set(ref, definition)
        end
      end
    end

    class EmptyRuleDeclaration < RuleDeclaration
      member :expr              # rule name
      member :condition_context # rule condition context

      def eval(env)
        rules = get_reference(env, expr, RuleExprSequence)
        rules.pieces.each do |piece|
          ref = piece.set(package_id: get_package_id(env, piece))
          definition = EmptyRuleDefinition.new(condition_context)
          env.rule_set(ref, definition)
        end
      end
    end
  end
end
