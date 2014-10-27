module Pione
  module PNML
    # `InputMergeComplement` is a net rewriting rule. This rule complements the
    # name of input-merged empty place. For example, the net like the following
    #
    #     'p1' --> empty transition --+
    #                                 |
    #     'p2' --> empty transition --+--> empty place -> A
    #                                 |
    #     'p3' --> empty transition --+
    #
    # is rewritten as the following.
    #
    #     'p1' --> empty transition --+
    #                                 |
    #     'p2' --> empty transition --+--> 'p1' or 'p2' or 'p3' -> A
    #                                 |
    #     'p3' --> empty transition --+
    module InputMergeComplement
      # Find subjects(source transitions and target palce) of this rule from the
      # net. The conditions are followings:
      #
      # - There is an empty target place.
      # - There are more than 2 empty source transitions.
      # - Each source transition has only one named place as the input condition.
      # - There are arcs that connect sources and the target.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param env [Lang::Environment]
      #   language environment
      # @return [Array]
      #   source transitions and target place
      def self.find_subjects(net, env)
        net.places.each do |place|
          # target place should be empty
          next unless Perspective.empty_place?(place)

          # collect transitions
          transitions = net.find_all_transitions_by_target_id(place.id).select do |transition|
            arcs = net.find_all_arcs_by_target_id(transition.id)
            if arcs.size == 1
              _place = net.find_place(arcs.first.source_id)
              Perspective.empty_transition?(transition) and Perspective.data_place?(_place, env)
            end
          end

          # there should be more than 2 transitions
          next unless transitions.size > 1

          return [transitions, place]
        end

        return nil
      end

      # Rewrite subject place's name by using subject transitions.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param subjects [Array]
      #   source transitions and target place
      # @param env [Lang::Environment]
      #   language environment
      # @return [void]
      def self.rewrite(net, subjects, env)
        transitions, place = subjects

        source_places = transitions.map do |transition|
          net.find_all_places_by_target_id(transition.id)
        end.flatten

        # build a new name
        new_name = source_places.map do |source_place|
          Perspective.normalize_data_name(source_place.name)
        end.sort.join(" or ")

        # update the place name
        modifier = Perspective.data_modifier(place) || ""
        place.name = modifier + new_name
      end
    end
  end
end
