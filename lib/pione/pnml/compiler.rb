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

      # Compile a PNML file into PIONE document as a string.
      def compile
        # annotations
        annotations = AnnotationExtractor.new(@net, @option).extract

        # apply net rewriting rules
        @net_rewriter.rewrite(@net)

        # build rules
        rules, flow_elements = ConstituentRuleBuilder.new(@net, @net_name).build()
        definition_main = FlowRuleBuilder.new(@net, @net_name).build(flow_elements)

        # merge literate actions
        rules.each do |rule|
          if @option[:literate_actions]
            if action = @option[:literate_actions][rule.name]
              rule.action_content = action[:content]
            end
          end
        end

        # textize
        [*annotations, "", definition_main.textize, *rules.map {|rule| rule.textize}].join("\n")
      end
    end

    # ConstituentRuleBuilder builds constituent rule definitions.
    class ConstituentRuleBuilder
      # @param net [PNML::Net]
      #   net
      # @param net_name [String]
      #   name of the net
      def initialize(net, net_name)
        @net = net
        @net_name = net_name
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
          places = @net.find_all_places_by_target_id(transition.id)
          input_places = places.select {|place| Perspective.file?(place)}
          inputs = input_places.map {|input| Perspective.normalize_data_name(input.name)}

          case Perspective.normalize_data_name(transition.name)
          when Perspective::KEYWORD_IF
            flow_elements << create_if_branch(transition)
          when Perspective::KEYWORD_CASE
            flow_elements << create_case_branch(transition)
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
          if Perspective.rule?(transition)
            type = :action
            rule_name = Perspective.normalize_rule_name(transition.name)
            is_external = Perspective.external?(transition)
            rule = RuleDefinition.new(rule_name, type, is_external, @net_name, table.size)

            # setup rule conditions
            rule.inputs = find_inputs(transition)
            rule.outputs = find_outputs(transition)
            rule.params = find_params(transition)
            rule.constraints = find_constraints(transition)
            rule.source_tickets = find_source_tickets(transition)
            rule.target_tickets = find_target_tickets(transition)

            table[transition.id] = rule
          end
        end
      end

      # Find inputs from net.
      #
      # @param transition [Transition]
      #   base transition
      # @return [Array]
      #   rule inputs
      def find_inputs(transition)
        @net.find_all_places_by_target_id(transition.id).each_with_object([]) do |place, inputs|
          if Perspective.file?(place)
            inputs << Perspective.normalize_data_name(place.name)
          else
            begin
              # consideration for constraint nodes
              prev_transition = @net.find_transition_by_target_id(place.id)
              if Perspective.keyword_constraint?(prev_transition)
                @net.find_all_places_by_target_id(prev_transition.id).each do |_place|
                  if Perspective.file?(_place)
                    inputs << Perspective.normalize_data_name(_place.name)
                  end
                end
              end
            rescue AmbiguousNetQueryResult
              # ignore
            end
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
          if Perspective.file?(place)
            outputs << Perspective.normalize_data_name(place.name)
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
          if Perspective.param?(place)
            params << Param.new(place.name)
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
          keyword_constraints = prev_transitions.select{|t| Perspective.keyword_constraint?(t)}

          case keyword_constraints.size
          when 0
            # ignore
          when 1
            if Perspective.expr?(place)
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
          if Perspective.ticket?(place)
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
          if Perspective.ticket?(place)
            tickets << Ticket.new(place.name)
          end
        end
      end

      # Create a if-branch from the transiton.
      #
      # @param transition [PNML::Transition]
      #   base transition
      # @return [ConditionalBranch]
      #   conditional branch
      def create_if_branch(transition)
        condition = @net.find_place_by_source_id(transition.id)

        keywords = @net.find_all_transitions_by_source_id(condition.id)
        key_then = keywords.find{|key| Perspective.compact(key.name) == Perspective::KEYWORD_THEN}
        key_else = keywords.find{|key| Perspective.compact(key.name) == Perspective::KEYWORD_ELSE}

        branch = ConditionalBranch.new(:if, condition.name)

        find_next_rules(key_then).each do |transition|
          rule = definition[transition.id]
          rule.inputs += inputs
          flow_elements.delete(rule)
          branch.table[:then] << rule
        end

        find_next_rules(key_else).each do |transition|
          rule = definition[transition.id]
          rule.inputs += inputs
          flow_elements.delete(rule)
          branch.table[:else] << rule
        end

        return branch
      end

      # Create a case-branch from the transiton.
      #
      # @param transition [PNML::Transition]
      #   base transition
      # @return [ConditionalBranch]
      #   conditional branch
      def create_case_branch(transition)
        expr = @net.find_place_by_source_id(transition.id)

        keywords = @net.find_all_transtions_by_source_id(expr.id)
        keys_when = keywords.select{|key| Perspective.compact(key.name) == Perspective::KEYWORD_WHEN}
        key_else = keywords.find{|key| Perspective.compact(key.name) == Perspective::KEYWORD_ELSE}

        branch = ConditionalBranch.new(:case, expr.name)

        keys_when.each do |key|
          find_next_rules(key).each do |transition|
            rule = definition[transition.id]
            rule.inputs += inputs
            flow_elements.delete(rule)
            branch.table[key.name] << rule
          end
        end

        find_next_rules(key_else).each do |transition|
          rule = definition[transition.id]
          rule.inputs += inputs
          flow_elements.delete(rule)
          branch.table[:else] << rule
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
            if Perspective.rule?(transition)
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
      def initialize(net, net_name)
        @net = net
        @net_name = net_name
      end

      # Build a flow rule definition for PNML net.
      #
      # @param flow_elements [Array]
      #   flow elements
      # @return [RuleDefinition]
      #   a flow rule definition for PNML net
      def build(flow_elements)
        inputs = @net.places.select {|place| Perspective.file?(place) and Perspective.net_input?(place)}
        inputs = inputs.map {|input| Perspective.normalize_data_name(input.name)}

        outputs = @net.places.select {|place| Perspective.file?(place) and Perspective.net_output?(place)}
        outputs = outputs.map {|output| Perspective.normalize_data_name(output.name)}

        option = {
          :inputs => inputs,
          :outputs => outputs,
          :params => @net.places.select {|place| Perspective.param?(place) and Perspective.net_input?(place)},
          :flow_elements => flow_elements,
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
