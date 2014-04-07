module Pione
  module PNML
    # `OutputSynchronizationComplement` is a net rewriting rule. This rule
    # complements names of source places that forms output synchronization
    # pattern. For example, the net like the following
    #
    #     A --> empty place --+
    #                         |
    #     B --> empty place --+--> empty transition --> '*.p1'
    #                         |
    #     C --> empty place --+
    #
    # is written as the following.
    #
    #     A --> '*.p1' --+
    #                    |
    #     B --> '*.p1' --+--> empty transition --> '*.p1'
    #                    |
    #     C --> '*.p1' --+
    #
    module OutputSynchronizationComplement
      # Find subjects(source places and synchronized place) of this rule from
      # the net. The conditions are followings:
      #
      # - There are more than 2 source places.
      # - There is an empty target transition. It has only one output named
      #   place.
      # - There are arcs that connect sources and the target.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @return [Array]
      #   source places and synchronized place
      def self.find_subjects(net)
        net.transitions.each do |transition|
          # target transition should be empty
          next unless transition.empty_name?

          # the transition should have only one output place
          synchronized_places = net.find_all_places_by_source_id(transition.id).select do |place|
            PioneElement.file?(place)
          end
          next unless synchronized_places.size == 1

          # collect source places
          source_places = net.find_all_places_by_target_id(transition.id)
          next unless source_places.size > 1
          next unless source_places.any? {|place| place.empty_name?}

          # return subjects
          return [source_places, synchronized_places.first]
        end

        return nil
      end

      # Rewrite names of empty source places same as the name of synchronized place.
      #
      # @param net [PNML::Net]
      #   rewriting target net
      # @param subjects [Array]
      #   source places and synchronized place
      # @return [void]
      def self.rewrite(net, subjects)
        source_places, synchronized_place = subjects

        # rewrite names of empty source places
        source_places.each do |place|
          # rewrite name only if it is empty
          if place.empty_name?
            place.name = synchronized_place.name
          end
        end
      end
    end
  end
end
