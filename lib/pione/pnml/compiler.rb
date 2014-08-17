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
        end
      end

      # Compile a PNML file into PIONE document as a string.
      def compile
        # annotations
        annotations = AnnotationExtractor.new(@net, @option).extract

        # apply net rewriting rules
        @net_rewriter.rewrite(@net)

        # build rules
        rules, flow_elements = build_constituent_rule_definitions
        definition_main = build_flow_rule_definition(@option[:flow_rule_name] || "Main", flow_elements)

        # merge literate actions
        rules.each do |rule|
          if @option[:literate_action]
            if action = @option[:literate_action][rule.name]
              rule.action_content = action[:content]
            end
          end
        end

        # textize
        [*annotations, "", definition_main.textize, *rules.map {|rule| rule.textize}].join("\n")
      end

      private

      # Build constituent rule definitions by transitions in the net.
      def build_constituent_rule_definitions
        definition = @net.transitions.each_with_object({}) do |transition, table|
          if Perspective.rule?(transition)
            rule = RuleDefinition.new(transition.name)

            # inputs
            @net.find_all_places_by_target_id(transition.id).each do |place|
              if Perspective.file?(place)
                rule.inputs << Perspective.normalize_data_name(place.name)
              end
            end

            @net.find_all_places_by_source_id(transition.id).each do |place|
              # outputs
              if Perspective.file?(place)
                rule.outputs << Perspective.normalize_data_name(place.name)
              end

              # params
              if Perspective.param?(place)
                rule.params << Param.new(place.name, nil)
              end
            end

            table[transition.id] = rule
          end
        end

        # save all inner rules
        rules = definition.values.compact
        flow_elements = definition.values.compact

        # conditional branch
        @net.transitions.each do |transition|
          places = @net.find_all_places_by_target_id(transition.id)
          inputs = places.select {|place| Perspective.file?(place)}
          inputs = inputs.map {|input| Perspective.normalize_data_name(input.name)}

          case Perspective.normalize_data_name(transition.name)
          when "if"
            # if-branch
            condition = @net.find_place_by_source_id(transition.id)

            keywords = @net.find_all_transitions_by_source_id(condition.id)
            key_then = keywords.find{|key| Perspective.compact(key.name) == "then"}
            key_else = keywords.find{|key| Perspective.compact(key.name) == "else"}

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

            flow_elements << branch
          when "case"
            expr = @net.find_place_by_source_id(transition.id)

            keywords = @net.find_all_transtions_by_source_id(expr.id)
            keys_when = keywords.select{|key| Perspective.compact(key.name) == "then"}
            key_else = keywords.find{|key| Perspective.compact(key.name) == "else"}

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

            flow_elements << branch
          end
        end

        return [rules, flow_elements]
      end

      # Make a main rule.
      def build_flow_rule_definition(name, flow_elements)
        inputs = @net.places.select {|place| Perspective.file?(place) and Perspective.net_input?(place)}
        inputs = inputs.map {|input| Perspective.normalize_data_name(input.name)}

        outputs = @net.places.select {|place| Perspective.file?(place) and Perspective.net_output?(place)}
        outputs = outputs.map {|output| Perspective.normalize_data_name(output.name)}

        option = {
          :inputs => inputs,
          :outputs => outputs,
          :params => @net.places.select {|place| Perspective.param?(place) and Perspective.net_input?},
          :flow_elements => flow_elements,
        }

        RuleDefinition.new(name, option)
      end

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
  end
end
