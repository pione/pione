module Pione
  module PNML
    # `IsolatedElementElimination` is a net rewriting rule. This rule removes
    # isolated elememts from nets.
    module IsolatedElementElimination
      # Find subjects(an isolated element) by following criteria.
      #
      # - There is a place or transition.
      # - It has no arcs.
      def find_subjects(net)
        (net.places + net.transitions).each do |node|
          input_arcs = net.find_all_arcs_by_source_id(node.id)
          output_arcs = net.find_all_arcs_by_target_id(node.id)
          if input_arcs.empty? and output_arcs.empty?
            return node
          end
        end
      end

      # Rewrite the net by eliminating isolated node.
      def rewrite(net, subjects)
        node = subjects

        # eliminate
        net.transitions.delete(node)
        net.places.delete(node)
      end
    end
  end
end
