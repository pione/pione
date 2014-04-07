module Pione
  module PNML
    # `OutputReduction` is a net rewriting rule. This rule removes unnecessary
    # output nodes of transitions. For example, the net likes the following
    #
    #     A --> empty place --> empty transition --> place -->  B
    #
    # is rewritten as the following.
    #
    #     A -> place -> B
    #
    module OutputReduction
      # Return subjects(source place, target transition, and the arc) if the net
      # satisfies output reduction's condtions. The conditions are followings:
      #
      # - There is an empty source place. It is an output of named transition.
      # - There is an empty target transition.
      # - There is an arc that connects the source and the target.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @return [Array]
      #   source place, target transition, and the arc
      def self.find_subjects(net)
        net.places.each do |place|
          # source place should be empty
          next unless Perspective.empty?(place)

          # source place should be an output of named transition
          next if net.find_all_transitions_by_target_id(place.id).map do |transition|
            Perspective.named?(transition)
          end.empty?

          net.find_all_transitions_by_source_id(place.id).each do |transition|
            # target transition should be empty
            next unless Perspective.empty?(transition)

            return [place, transition, net.find_arc(place.id, transition.id)]
          end
        end

        return nil
      end

      # Rewrite the net with subjects by the following way.
      #
      # - Remove the subject place.
      # - Remove the subject transition.
      # - Remove the subject and related arcs.
      # - Connect discontinuous nodes by new arcs.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @return [void]
      def self.rewrite(net, subjects)
        place, transition, arc = subjects

        # remove subjects from the net
        net.places.delete(place)
        net.transitions.delete(transition)
        net.arcs.delete(arc)

        # remove related arcs
        input_arcs = net.find_all_arcs_by_target_id(place.id)
        input_arcs.each {|arc| net.arcs.delete(arc)}
        output_arcs = net.find_all_arcs_by_source_id(transition.id)
        output_arcs.each {|arc| net.arcs.delete(arc)}

        # append new arcs
        input_arcs.each do |input_arc|
          output_arcs.each do |output_arc|
            net.arcs << Arc.new(net, net.generate_id, input_arc.source_id, output_arc.target_id)
          end
        end
      end
    end
  end
end
