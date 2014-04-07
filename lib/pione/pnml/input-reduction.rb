module Pione
  module PNML
    # `InputReduction` is a net rewriting rule. This rule removes unnecessary
    # input nodes of transitions by following criteria. For example, the net
    # likes the following
    #
    #     A --> place --> empty transition --> empty place --> B
    #
    # is rewritten as the following.
    #
    #     A -> place -> B
    #
    module InputReduction
      # Return subjects(source transtion, target place, and the arc) if the net
      # satisfies input reduction's condtions. The conditions are followings:
      #
      # - There is an empty source transition.
      # - There is an empty target place. It is an input of named transition.
      # - There is an arc that connects the source and the target.
      def self.find_subjects(net)
        net.transitions.each do |transition|
          # source transition has empty name
          next unless Perspective.named?(transition)

          net.find_all_places_by_source_id(transition.id).each do |place|
            # target place has empty name
            next unless Perspective.empty?(place)

            # target place should be an output of named transition
            net.find_all_transitions_by_source_id(place.id).each do |rule|
              if Perspective.named?(rule)
                return [transition, place, net.find_arc(transition.id, place.id)]
              end
            end
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
      def self.rewrite(net, subjects)
        transition, place, arc = subjects

        # remove subjects from the net
        net.places.delete(place)
        net.transitions.delete(transition)
        net.arcs.delete(arc)

        # remove related arcs
        input_arcs = net.find_all_arcs_by_target_id(transition.id)
        input_arcs.each {|arc| net.arcs.delete(arc)}
        output_arcs = net.find_all_arcs_by_source_id(place.id)
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
