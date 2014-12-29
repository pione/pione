module Pione
  module PNML
    # `InputReduction` is a net rewriting rule. This rule removes unnecessary
    # input nodes of transitions by following criteria. For example, the net
    # likes the following(A and B are transitions)
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
      def self.find_subjects(net, env)
        net.transitions.each do |rule|
          # rule has its name
          next if Perspective.empty?(env, rule)

          # find source places
          net.find_all_places_by_target_id(rule.id).each do |place|
            # the source place has empty name
            next unless Perspective.empty?(env, place)

            # find transtions that generates the source place
            transitions = net.find_all_transitions_by_target_id(place.id)

            # only one transtion
            if transitions.size == 1
              transition = transitions.first

              # the transition is connected to only one place at target side
              if net.find_all_places_by_source_id(transition.id).size == 1
                # the transition has empty name
                if Perspective.empty?(env, transition)
                  return [transition, place, net.find_arc(transition.id, place.id)]
                end
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
      def self.rewrite(net, subjects, env)
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
