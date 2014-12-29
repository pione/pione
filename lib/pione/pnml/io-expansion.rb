module Pione
  module PNML
    # `IOException` is a net rewriting rule. This rule transforms nets by
    # expanding file places that are sandwiched by source and target rule
    # transitions. For example, the net like the following
    #
    #    A --> 'p1' --> B
    #
    # is written as the following.
    #
    #    A --> 'p1' --> empty transition --> 'p1' --> B
    #
    module IOExpansion
      # Find subjects(sandwiched place and target side arcs) of this rule from
      # the net. The conditions are followings:
      #
      # - There is a file place.
      # - There are rule transitions.
      # - There are arcs that connect the file place and the rule transitions.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param env [Lang::Environment]
      #   language environment
      # @return [Array]
      #   sandwiched place and target side arcs
      def self.find_subjects(net, env)
        net.transitions.each do |transition|
          # transition should be a rule
          next unless Perspective.rule_transition?(env, transition)

          net.find_all_places_by_source_id(transition.id).each do |place|
            # place should be a file
            next unless Perspective.data_place?(env, place)

            # collect target side arcs
            all_target_arcs = net.find_all_arcs_by_source_id(place.id)
            target_arcs = all_target_arcs.select do |arc|
              transition = net.find_transition(arc.target_id)
              transition and Perspective.rule_transition?(env, transition)
            end
            next unless target_arcs.size > 0

            # return subjects
            return [place, target_arcs]
          end
        end

        return nil
      end

      # Rewrite the net with subjects by the following way.
      #
      # - Remove subject target arcs
      # - Add a copied place and an accommodation transition.
      # - Connect discontinuous nodes by new arcs.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param subjects [Array]
      #   sandwiched place and target side arcs
      # @param env [Lang::Environment]
      #   language environment
      # @return [void]
      def self.rewrite(net, subjects, env)
        place, target_arcs = subjects

        # remove arcs
        target_arcs.each {|arc| net.arcs.delete(arc)}

        # create an expanded place
        expanded_place = Place.new(net, net.generate_id, place.name)
        net.places << expanded_place

        # create an accommodation transition
        transition = Transition.new(net, net.generate_id)
        net.transitions << transition

        # connect original place and accommodation transition
        net.arcs << Arc.new(net, net.generate_id, place.id, transition.id)

        # connect accommodation transition and expanded place
        net.arcs << Arc.new(net, net.generate_id, transition.id, expanded_place.id)

        # connect expanded place and rule transtions
        target_arcs.each do |arc|
          net.arcs << Arc.new(net, net.generate_id, expanded_place.id, arc.target_id)
        end
      end
    end
  end
end
