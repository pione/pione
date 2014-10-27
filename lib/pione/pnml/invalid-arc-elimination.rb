module Pione
  module PNML
    # `InvalidArcElimination` is a net rewriting rule. This rule removes invalid
    # arcs from nets.
    module InvalidArcElimination
      # Find subjects(an invalid arc) by following criteria.
      #
      # - There is a arc.
      # - It should connect source place and target transition, or source
      #   transition and target place.
      def self.find_subjects(net, env)
        net.arcs.each do |arc|
          source_transition = net.find_transition(arc.source_id)
          source_place = net.find_place(arc.source_id)
          target_transition = net.find_transition(arc.target_id)
          target_place = net.find_place(arc.target_id)

          # arc from transition to place
          cond1 = not(source_transition.nil?) && not(target_place.nil?)

          # arc from place to transition
          cond2 = not(source_place.nil?) && not(target_transition.nil?)

          unless cond1 or cond2
            return [arc]
          end
        end

        return nil
      end

      # Rewrite the net by eliminating isolated node.
      def self.rewrite(net, subjects, env)
        arc = subjects.first

        # eliminate
        net.arcs.delete(arc)
      end
    end
  end
end
