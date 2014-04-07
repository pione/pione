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
        @this_flow_name = option[:flow_name] || "Main"
        @package_name = option[:package_name]
        @editor = option[:editor]
        @tag = option[:tag]
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
        annotations = AnnotationExtractor.extract(@net)

        # apply net rewriting rules
        @net_rewriter.rewrite(@net)

        # build rules
        build_constituent_rule_definitions
        build_flow_rule_definition

        # textize
        [*annotations, "", flow_rule_definition.textize, *constituent.map {|c| c.textize}].join("\n")
      end

      private

      # Setup rule definitions by transitions in the net.
      def setup_rule_definitions
        definition = @net.transitions.each_with_object(Hash.new) do |transition, table|
          if PioneElement.rule?(transition)
            rule = ConstituentRule.new(transition.name)

            # inputs
            @net.find_all_places_by_target_id(transition.id).each do |place|
              if PioneElement.file?(place)
                rule.inputs << PioneElement.normalize_data_name(place.name)
              end
            end

            # outputs
            @net.find_all_places_by_source_id(transition.id).each do |place|
              if PioneElement.file?(place)
                rule.outputs << PioneElement.normalize_data_name(place.name)
              end
            end

            # params
            @net.find

            table[transition.id] = transition
          end
        end

        # setup rule's inputs by arcs which have the direction from place to
        # transition
        @net.pt_arcs.each do |arc|
          if data_condition = data_expr.has_key?(arc.source_id)
            definition[arc.target_id].add_input_condition(data_condition)
          end
        end

        # setup rule's inputs by arcs which have the direction from place to
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
        params = @net.places.select {|place| this_flow_input?(place) and PioneElement.param?(palce)}
        inputs = @net.places.select {|place| this_flow_input?(place) and PioneElement.file?(place)}
        outputs = @net.places.select {|place| this_flow_output?(palce) and PioneElement.file?(place)}

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
