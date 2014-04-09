module Pione
  module PNML
    # `InputParallelizationComplement` is a net rewriting rule. This rule
    # complements names of empty places that form input parallelization
    # pattern. For example, the net likes the following
    #
    #                                 +--> empty place --> A
    #                                 |
    #     'p1' --> empty transition --+--> empty place --> B
    #                                 |
    #                                 +--> empty place --> C
    #
    # is rewritten as the following.
    #
    #                                 +--> 'p1' --> A
    #                                 |
    #     'p1' --> empty transition --+--> 'p1' --> B
    #                                 |
    #                                 +--> 'p1' --> C
    #
    module InputParallelizationComplement
      # Find subjects(input place and target places) of this rule from the
      # net. The conditions are followings:
      #
      # - There is an empty source transition. It has only one named place as an
      #   input.
      # - There are more than 2 target places that includes empty place.
      # - There are arcs that connect the source and targets.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @return [Array]
      #   input place and target places
      def self.find_subjects(net)
        net.transitions.each do |transition|
          # source transition should have no names
          next unless transition.empty_name?

          # transition should have only one named input
          input_places = net.find_all_places_by_target_id(transition.id)
          unless input_places.size == 1 and Perspective.file?(input_places.first)
            next
          end

          # collect places
          output_places = net.find_all_places_by_source_id(transition.id)
          next unless output_places.all? {|output_place| output_place.empty_name?}

          # there should be more than 2 places
          next unless output_places.size > 1

          return [input_places.first, output_places]
        end

        return nil
      end

      # Rewrite targe place's name same as input place's name.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param subjects [Array]
      #   input place and target places
      # @return [void]
      def self.rewrite(net, subjects)
        input_place, target_places = subjects

        # rewrite names of target places
        target_places.each do |place|
          place.name = Perspective.normalize_data_name(input_place.name)
        end
      end
    end
  end
end
