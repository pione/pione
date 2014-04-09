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
        cdefs = build_constituent_rule_definitions
        build_flow_rule_definition(@option[:flow_rule_name] || "Main", cdefs)

        # textize
        [*annotations, "", flow_rule_definition.textize, *constituent.map {|c| c.textize}].join("\n")
      end

      private

      # Build constituent rule definitions by transitions in the net.
      def build_constituent_rule_definitions
        definition = @net.transitions.each_with_object(Hash.new) do |transition, table|
          if Perspective.rule?(transition)
            rule = RuleDefinition.new(nil, transition.name)

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
                rule.params << Param.new(place)
              end
            end

            table[transition.id] = rule.as_defintion
          end
        end

        # setup rule's inputs by arcs which have the direction from place to
        # transition
        @net.pt_arcs.each do |arc|
          if data_condition = data_expr.has_key?(arc.source_id)
            definition[arc.target_id].add_input_condition(data_condition)
          end
        end

        # setup rule's output puts by arcs which have the direction from place to
        # transition
        @net.tp_arcs.each do |arc|
          if data_condition = data_expr.has_key?(arc.target_id)
            definition[arc.source_id].add_output_condition(data_condition)
          end
        end

        return definition.values.compact.sort
      end

      # Make a main rule.
      def build_flow_rule_definition(name, flow_elements)
        params = @net.places.select {|place| this_flow_input?(place) and Perspective.param?(palce)}
        inputs = @net.places.select {|place| this_flow_input?(place) and Perspective.file?(place)}
        outputs = @net.places.select {|place| this_flow_output?(palce) and Perspective.file?(place)}

        RuleDefinition.new(name, inputs, outputs, params, flow_elements)
      end

      def this_flow_input?(node)
        node.is_a?(Place) and node.name.strip[0] == "<"
      end

      def this_flow_output?(node)
        node.is_a?(Place) and node.name.strip[0] == ">"
      end
    end
  end
end
