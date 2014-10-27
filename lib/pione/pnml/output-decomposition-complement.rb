module Pione
  module PNML
    # `OutputDecompositionComplement` is a net transformational rule. This rule
    # complements name of source place that forms output decomposition
    # pattern. For example, the net likes following
    #
    #                   +--> empty transition --> 'p1'
    #                   |
    #     empty place --+--> empty transition --> 'p2'
    #                   |
    #                   +--> empty transition --> 'p3'
    #
    # is rewritten as th following.
    #
    #                            +--> empty transition --> 'p1'
    #                            |
    #     'p1' or 'p2' or 'p3' --+--> empty transition --> 'p2'
    #                            |
    #                            +--> empty transition --> 'p3'
    #
    module OutputDecompositionComplement
      # Find subjects(source place and component places) of this rule from
      # net. The conditions are followings:
      #
      # - There is an empty source place.
      # - There are more than 2 target transitions. All traget transitions are
      #   empty, and each target transition has only one output named place.
      # - There are arcs that connect the source and targets.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param env [Lang::Environment]
      #   language environment
      # @return [Array]
      #   source place and component places
      def self.find_subjects(net, env)
        net.places.each do |place|
          # source place should be empty
          next unless Perspective.empty_place?(place)

          # there should be more than 2 target transitions
          transitions = net.find_all_transitions_by_source_id(place.id)
          next unless transitions.size > 1
          next unless transitions.all? {|transition| Perspective.empty_transition?(transition)}

          # each transition has only one output named place
          component_places = []
          next unless transitions.all? do |transition|
            _places = net.find_all_places_by_source_id(transition.id)
            component_places.concat(_places)
            _places.size == 1 and not(Perspective.empty_place?(_places.first))
          end

          return [place, component_places]
        end

        return nil
      end

      # Rewrite source place's name as disjunction of component place's name.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param subjects [Array]
      #   source place and component places
      # @param env [Lang::Environment]
      #   language environment
      # @return [void]
      def self.rewrite(net, subjects, env)
        place, component_places = subjects

        # component places' names
        names = component_places.map do |component_place|
          Perspective.normalize_data_name(component_place.name)
        end

        modifier = Perspective.data_modifier(place) || ""
        place.name = modifier + names.sort.join(" or ")
      end
    end
  end
end
