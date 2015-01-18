module Pione
  module PNML
    class Compiler
      # Compile from the net to PIONE document.
      #
      # @param net [PNML::Net]
      #   source net
      # @return [String]
      #   compiled PIONE document
      def self.compile(net, option={})
        new(net, option).compile
      end

      def initialize(net, option={})
        @net = net
        @net_name = option[:flow_rule_name] || "Main"
        @env = option[:env] || Lang::Environment.new
        setup_env(option[:package_pione])

        @option = option
        @net_rewriter = NetRewriter.new do |rules|
          rules << IsolatedElementElimination
          rules << InvalidArcElimination
          rules << OutputReduction
          rules << InputReduction
          rules << IOExpansion
          rules << InputMergeComplement
          rules << InputParallelizationComplement
          rules << OutputDecompositionComplement
          rules << OutputSynchronizationComplement
          rules << TicketInstantiation
        end
        @actions = []
      end

      def setup_env(package_pione)
        @env = @env.setup_new_package(:pnml_compiler)

        if package_pione.exist?
          parsed = Lang::DocumentParser.new.parse(package_pione.read)
          package_document = Lang::DocumentTransformer.new.apply(parsed, {package_name: true, filename: true})
          package_document.eval(@env)
        end

        val = Lang::KeyedSequence.new
        val = val.put(Lang::IntegerSequence.of(1), Lang::DataExprSequence.of("pnml_compiler"))
        @env.variable_set!(Lang::Variable.new("I"), val)
        @env.variable_set!(Lang::Variable.new("*"), Lang::StringSequence.of("pnml_compiler"))
        @env.variable_set!(Lang::Variable.new("O"), val)
      end

      # Compile a PNML file into PIONE document as a string.
      def compile
        # annotations
        annotations = AnnotationExtractor.new(@net, @option).extract
        declarations = DeclarationExtractor.new(@env, @net).extract

        # apply net rewriting rules
        @net_rewriter.rewrite(@net, @env)

        # build rules
        rules, flow_elements = ConstituentRuleBuilder.new(@net, @net_name, @env).build()
        definition_main = FlowRuleBuilder.new(@net, @net_name, @env).build(
          flow_elements,
          declarations.params,
          declarations.features,
          declarations.variable_bindings
        )

        # merge literate actions
        rules.each do |rule|
          if @option[:literate_actions]
            if action = @option[:literate_actions][rule.name]
              rule.action_content = action[:content]
            end
          end
        end

        # textize
        sections = []
        if annotations and annotations.size > 0
          sections << annotations << ""
        end
        sections << definition_main.textize
        rules.each {|rule| sections << rule.textize}
        return sections.join("\n")
      end
    end

    # ConstituentRuleBuilder builds constituent rule definitions.
    class ConstituentRuleBuilder
      # @param net [PNML::Net]
      #   net
      # @param net_name [String]
      #   name of the net
      # @param env [Lang::Environment]
      #   language environment
      def initialize(net, net_name, env)
        @net = net
        @net_name = net_name
        @env = env
      end

      # Build a consituent rule definitions by transitions in the net.
      #
      # @return [Array(Array<RuleDefinition>,Array)]
      def build
        definition = build_rule_definition_table()

        # save all inner rules
        rules = definition.values.compact
        flow_elements = definition.values.compact

        # conditional branch
        @net.transitions.each do |transition|
          inputs = @net.find_all_places_by_target_id(transition.id).select do |place|
            Perspective.data_place?(@env, place)
          end.map {|input| InputData.new(input)}

          if Perspective.if_transition?(@env, transition)
            flow_elements << create_if_branch(transition, definition, inputs, flow_elements)
          elsif Perspective.case_transition?(@env, transition)
            flow_elements << create_case_branch(transition, definition, inputs, flow_elements)
          end
        end

        return [rules, flow_elements]
      end

      private

      # Build rule definition table.
      #
      # @return [Hash{String=>RuleDefinition}]
      #   relatioin table between transition ID and rule definition
      def build_rule_definition_table
        return @net.transitions.each_with_object({}) do |transition, table|
          if Perspective.rule_transition?(@env, transition)
            type = :action
            rule_name = LabelExtractor.extract_rule_expr(transition.name)
            is_external = Perspective.external_rule_transition?(@env, transition)
            rule = RuleDefinition.new(rule_name, type, is_external, @net_name, table.size)

            # setup rule conditions
            rule.inputs = find_inputs(transition)
            rule.outputs = find_outputs(transition)
            rule.params = find_params(transition)
            rule.constraints = find_constraints(transition)
            rule.source_tickets = find_source_tickets(transition)
            rule.target_tickets = find_target_tickets(transition)
            rule.features = find_features(transition)

            table[transition.id] = rule
          end
        end
      end

      # Find inputs from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array<InputData>]
      #   rule inputs
      def find_inputs(transition)
        @net.find_all_places_by_target_id(transition.id).each_with_object([]) do |place, inputs|
          begin
            # consideration for constraint nodes
            prev_transition = @net.find_transition_by_target_id(place.id)
            if Perspective.constraint_transition?(@env, prev_transition)
              @net.find_all_places_by_target_id(prev_transition.id).each do |_place|
                if Perspective.data_place?(@env, _place)
                  inputs << InputData.new(_place)
                end
              end
            else
              if Perspective.data_place?(@env, place)
                inputs << InputData.new(place)
              end
            end
          rescue AmbiguousNetQueryResult
            # ignore
          end
        end
      end

      # Find outputs from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array]
      #   rule outputs
      def find_outputs(transition)
        @net.find_all_places_by_source_id(transition.id).each_with_object([]) do |place, outputs|
          if Perspective.data_place?(@env, place)
            outputs << OutputData.new(place)
          end
        end
      end

      # Find parameters from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array<Param>]
      #   rule parameters
      def find_params(transition)
        @net.find_all_places_by_target_id(transition.id).each_with_object([]) do |place, params|
          if Perspective.param_place?(@env, place)
            prev_transitions = @net.find_all_transitions_by_target_id(place.id)
            keyword_transitions = prev_transitions.select{|t| Perspective.keyword_transition?(@env, t)}
            if keyword_transitions.empty?
              params << Param.set_of(place)
            end
          end
        end
      end

      # Find constraints from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array<Constraint>]
      #   rule constraints
      def find_constraints(transition)
        @net.find_all_places_by_target_id(transition.id).each_with_object([]) do |place, constraints|
          prev_transitions = @net.find_all_transitions_by_target_id(place.id)
          constraint_transitions = prev_transitions.select{|t| Perspective.constraint_transition?(@env, t)}

          case constraint_transitions.size
          when 0
            # ignore
          when 1
            if Perspective.expr_place?(@env, place)
              constraints << Constraint.new(place.name)
            else
              # the place should be constraint expression
              raise CompilerError.should_be_constraint_expr(place)
            end
          else
            # multiple constraint keywords found
            raise CompilerError.multiple_constraint_keywords(transition.name)
          end
        end
      end

      # Find source tickets from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array<Ticket>]
      #   tickets
      def find_source_tickets(transition)
        @net.find_all_places_by_target_id(transition.id).each_with_object([]) do |place, tickets|
          if Perspective.ticket_place?(@env, place)
            tickets << Ticket.new(place.name)
          end
        end
      end

      # Find target tickets from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array<Ticket>]
      #   tickets
      def find_target_tickets(transition)
        @net.find_all_places_by_source_id(transition.id).each_with_object([]) do |place, tickets|
          if Perspective.ticket_place?(@env, place)
            tickets << Ticket.new(place.name)
          end
        end
      end

      # Find features from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array<Feature>]
      #   features
      def find_features(transition)
        @net.find_all_places_by_target_id(transition.id).each_with_object([]) do |place, features|
          if Perspective.feature_place?(@env, place)
            keyword_transitions = @net.find_all_transitions_by_target_id(place.id).select do |t|
              Perspective.keyword_transition?(@env, t)
            end
            if keyword_transitions.empty?
              features << Feature.new(place.name)
            end
          end
        end
      end

      # Create a if-branch from the transiton.
      #
      # @param transition [PNML::Transition]
      #   base transition
      # @return [ConditionalBranch]
      #   conditional branch
      def create_if_branch(transition, definition, inputs, flow_elements)
        condition = @net.find_place_by_source_id(transition.id)

        nodes = @net.find_all_transitions_by_source_id(condition.id)
        key_then = nodes.find{|node| Perspective.then_transition?(@env, node)}
        key_else = nodes.find{|node| Perspective.else_transition?(@env, node)}

        branch = ConditionalBranch.new(:if, condition.name)

        find_next_rules(key_then).each do |transition|
          rule = definition[transition.id]
          rule.inputs += inputs
          flow_elements.delete(rule)
          branch.table[:then] << rule
        end

        if key_else
          find_next_rules(key_else).each do |transition|
            rule = definition[transition.id]
            rule.inputs += inputs
            flow_elements.delete(rule)
            branch.table[:else] << rule
          end
        end

        return branch
      end

      # Create a case-branch from the transiton.
      #
      # @param transition [PNML::Transition]
      #   base transition
      # @return [ConditionalBranch]
      #   conditional branch
      def create_case_branch(transition, definition, inputs, flow_elements)
        expr = @net.find_place_by_source_id(transition.id)

        nodes = @net.find_all_transitions_by_source_id(expr.id)
        keys_when = nodes.select{|node| Perspective.when_transition?(@env, node)}
        key_else = nodes.find{|node| Perspective.else_transition?(@env, node)}

        branch = ConditionalBranch.new(:case, expr.name)

        keys_when.each do |key|
          find_next_rules(key).each do |transition|
            rule = definition[transition.id]
            rule.inputs += inputs
            flow_elements.delete(rule)
            conditional_value_place = @net.find_place_by_source_id(key.id)
            branch.table[conditional_value_place.name] << rule
          end
        end

        if key_else
          find_next_rules(key_else).each do |transition|
            rule = definition[transition.id]
            rule.inputs += inputs
            flow_elements.delete(rule)
            branch.table[:else] << rule
          end
        end

        return branch
      end

      # Find next rules.
      #
      # @param base_rule [PNML::Transition]
      #   base transition
      def find_next_rules(base_rule)
        @net.find_all_places_by_source_id(base_rule.id).each_with_object([]) do |place, res|
          @net.find_all_transitions_by_source_id(place.id).each do |transition|
            if Perspective.rule_transition?(@env, transition)
              res << transition
            else
              find_next_rules(transition)
            end
          end
        end
      end
    end

    # FlowRuleBuilder builds a flow rule definition for PNML net.
    class FlowRuleBuilder
      # @param net [PNML::Net]
      #   PNML net
      # @param net_name [String]
      #   name of the net
      # @param env [Lang::Environment]
      #   language environment
      def initialize(net, net_name, env)
        @net = net
        @net_name = net_name
        @env = env
      end

      # Build a flow rule definition for PNML net.
      #
      # @param flow_elements [Array]
      #   flow elements
      # @return [RuleDefinition]
      #   a flow rule definition for PNML net
      def build(flow_elements, params, features, variable_bindings)
        inputs = @net.places.select {|place| Perspective.net_input_data_place?(@env, place)}
        inputs = inputs.map {|input| InputData.new(input)}

        outputs = @net.places.select {|place| Perspective.net_output_data_place?(@env, place)}
        outputs = outputs.map {|output| OutputData.new(output)}

        option = {
          :inputs => inputs,
          :outputs => outputs,
          :params => params,
          :features => features,
          :variable_bindings => variable_bindings,
          :flow_elements => flow_elements
        }

        RuleDefinition.new(@net_name, :flow, false, @net_name, 0, option)
      end
    end

    # CompilerError represents compiler errors.
    class CompilerError < StandardError
      # Raise an exception for the case of invalid constraint expression.
      #
      # @param node [Node]
      #   node that has invalid constraint expression
      def self.should_be_constraint_expr(node)
        new('The node "%s" should be a PIONE expression because of constraint keyword.' % node.name)
      end

      # Raise an exception for the case multiple constraint keywords found.
      #
      # @param rule_name [String]
      #   rule name
      def self.multiple_constraint_keywords(rule_name)
        new('Cannot connect multiple constraint nodes with rule "%s".' % rule_name)
      end
    end
  end
end
