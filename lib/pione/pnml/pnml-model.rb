module Pione
  module PNML
    # `Net` represents a net in PNML. PIONE handles PT-nets only, so this is
    # consisted by places, transitions, and arcs.
    class Net < StructX
      # all places in the net
      member :places, :default => lambda{ Array.new }

      # all transitions in the net
      member :transitions, :default => lambda{ Array.new }

      # all arcs in the net
      member :arcs, :default => lambda{ Array.new }

      # Generate a new PNML's ID.
      def generate_id
        Util::UUID.generate
      end

      # Return true if the net is valid. The criterion of validness is that all
      # arcs connect places and transitions.
      #
      # @return [Boolean]
      #   true if the net is valid
      def valid?
        arcs.each do |arc|
          source_transition = find_transition(arc.source_id)
          source_place = find_place(arc.source_id)
          target_transition = find_transition(arc.target_id)
          target_place = find_place(arc.target_id)

          # arc from transition to place
          cond1 = not(source_transition.nil?) && not(target_place.nil?)

          # arc from place to transition
          cond2 = not(source_place.nil?) && not(target_transition.nil?)

          unless cond1 or cond2
            return false
          end
        end

        return true
      end

      # Find the arc that connects from the source ID to the target ID. If no
      # arcs found, return `nil`.
      #
      # @param source_id [String]
      #   source ID
      # @param target_id [String]
      #   target ID
      # @return [PNML::Arc]
      #   the arc, or `nil`
      def find_arc(source_id, target_id)
        _arcs = arcs.select {|arc| arc.source_id == source_id and arc.target_id == target_id}

        # the result shouldn't be ambiguous
        if _arcs.size > 1
          raise AmbiguousNetQueryResult.new(__method__, place_id, _transitions)
        end

        return _arcs.first
      end

      # Find all arcs by the source ID.
      #
      # @param source_id [String]
      #   source ID
      # @return [Array<Arc>]
      #   result arcs
      def find_all_arcs_by_source_id(source_id)
        _arcs = arcs.select {|arc| arc.source_id == source_id}

        if block_given?
          _arcs.each {|arc| yield arc}
        else
          return _arcs
        end
      end

      # Find all arcs by the target ID.
      #
      # @param target_id [String]
      #   target ID
      # @return [Array<Arc>]
      #   result arcs
      def find_all_arcs_by_target_id(target_id)
        _arcs = arcs.select {|arc| arc.target_id == target_id}

        if block_given?
          _arcs.each {|arc| yield arc}
        else
          return _arcs
        end
      end

      # Return all arcs which have the direction from transtion to place.
      #
      # @return [Array<PNML::Arc>]
      #   arcs
      def tp_arcs
        _arcs = arcs.select {|arc| arc.from_transition_to_place?}

        if block_given?
          _arcs.each {|arc| yield arc}
        else
          return _arcs
        end
      end

      # Return all arcs which have the direction from place to transition.
      #
      # @return [Array<PNML::Arc>]
      #   arcs
      def pt_arcs
        _arcs = arcs.select {|arc| arc.from_place_to_transition?}

        if block_given?
          _arcs.each {|arc| yield arc}
        else
          return _arcs
        end
      end

      # Find a transition by ID.
      #
      # @param id [String]
      #   transition ID
      # @return [Transition]
      #   transition
      def find_transition(id)
        transitions.find {|transition| transition.id == id}
      end

      # Find a transition by the name.
      #
      # @param name [String]
      #   the transition name
      # @return [Transition]
      #   a transition, or nil
      def find_transition_by_name(name)
        _transitions = find_all_transitions_by_name(name)

        # the result shouldn't be ambiguous
        if _transitions.size > 1
          raise AmbiguousNetQueryResult.new(__method__, place_id, _transitions)
        end

        return _transitions.first
      end

      # Find all transitions by the name.
      #
      # @param name [String]
      #   transition's name
      # @return [Array<Transition>]
      #   transitions
      def find_all_transitions_by_name(name)
        _transitions = transitions.select {|transition| transition.name == name}

        if block_given?
          _transitions.each {|transition| yield transition}
        else
          return _transitions
        end
      end

      # Find a transition by the source place ID.
      #
      # @param place_id [String]
      #   place ID
      # @return [Array<Transition>]
      #   result transitions
      def find_transition_by_source_id(place_id)
        _transitions = find_all_transitions_by_source_id(place_id)

        # the result shouldn't be ambiguous
        if _transitions.size > 1
          raise AmbiguousNetQueryResult.new(__method__, place_id, _transitions)
        end

        return _transitions.first
      end

      # Find all transitions by the source place ID.
      #
      # @param place_id [String]
      #   place ID
      # @return [Array<Transition>]
      #   result transitions
      def find_all_transitions_by_source_id(place_id)
        _arcs = arcs.select {|arc| arc.source_id == place_id}
        _transitions = _arcs.map do |arc|
          transitions.find {|transition| transition.id == arc.target_id}
        end.compact.uniq

        if block_given?
          _transitions.each {|transition| yield transition}
        else
          return _transitions
        end
      end

      # Find a transition by the target place ID.
      #
      # @param place_id [String]
      #   place ID
      # @return [Array<Transition>]
      #   result transitions
      def find_transition_by_target_id(target_id)
        _transitions = find_all_transitions_by_target_id(target_id)

        # the result shouldn't be ambiguous
        if _transitions.size > 1
          raise AmbiguousNetQueryResult.new(__method__, place_id, _transitions)
        end

        return _transitions.first
      end

      # Find all transitions by the target place ID.
      #
      # @param place_id [String]
      #   place ID
      # @return [Array<Transition>]
      #   result transitions
      def find_all_transitions_by_target_id(target_id)
        _arcs = arcs.select {|arc| arc.target_id == target_id}
        _transitions = _arcs.map do |arc|
          transitions.find {|transition| transition.id == arc.source_id}
        end.compact.uniq

        if block_given?
          _transitions.each {|transition| yield transition}
        else
          return _transitions
        end
      end

      # Find a place by ID.
      #
      # @param id [String]
      #   the place ID
      # @return [Place]
      #   place
      def find_place(id)
        places.find {|place| place.id == id}
      end

      # Find a place by the name.
      #
      # @param name [String]
      #   the place name
      # @return [Place]
      #   a place, or nil
      def find_place_by_name(name)
        _places = find_all_places_by_name(name)

        # the result shouldn't be ambiguous
        if _places.size > 1
          raise AmbiguousNetQueryResult.new(__method__, name, _places)
        end

        return _places.first
      end

      # Find places by the name.
      #
      # @param name [String]
      #   place name
      # @return [Array<Place>]
      #   places
      def find_all_places_by_name(name)
        _places = places.select {|place| place.name == name}

        if block_given?
          _places.each {|place| yield place}
        else
          return _places
        end
      end

      # Find a place by the source transition ID.
      #
      # @param transition_id [String]
      #   transition ID
      # @return [Array<Transition>]
      #   a result place
      def find_place_by_source_id(transition_id)
        _places = find_all_places_by_source_id(transition_id)

        # the result shouldn't be ambiguous
        if _places.size > 1
          raise AmbiguousNetQueryResult.new(__method__, name, _places)
        end

        return _places.first
      end

      # Find all places by the source transition ID.
      #
      # @param transition_id [String]
      #   transition ID
      # @return [Array<Transition>]
      #   result places
      def find_all_places_by_source_id(transition_id)
        _arcs = arcs.select {|arc| arc.source_id == transition_id}
        _places = _arcs.map do |arc|
          places.find {|place| place.id == arc.target_id}
        end.compact.uniq

        if block_given?
          _places.each {|place| yield place}
        else
          return _places
        end
      end

      # Find a place by the target transition ID.
      #
      # @param transition_id [String]
      #   transition ID
      # @return [Array<Transition>]
      #   result places
      def find_place_by_target_id(transition_id)
        _places = find_all_places_by_target_id(transition_id)

        # the result shouldn't be ambiguous
        if _places.size > 1
          raise AmbiguousNetQueryResult.new(__method__, name, _places)
        end

        return _places.first
      end

      # Find all places by the target transition ID.
      #
      # @param transition_id [String]
      #   transition ID
      # @return [Array<Transition>]
      #   result places
      def find_all_places_by_target_id(transition_id)
        _arcs = arcs.select {|arc| arc.target_id == transition_id}
        _places = _arcs.map do |arc|
          places.find {|place| place.id == arc.source_id}
        end.compact.uniq

        if block_given?
          _places.each {|place| yield place}
        else
          return _places
        end
      end
    end

    # `Node` is a meta class for `Place` and `Transition`.
    class Node < StructX
      # Eliminate comments from the string. This implementation is temporary, we
      # should fix this.
      def eliminate_comment(str)
        # FIXME
        str.sub(/#.*$/, "")
      end

      # Return true if the name is empty.
      def empty_name?
        name.nil? or /^\s*[<>]?\s*$/.match(eliminate_comment(name))
      end

      def inspect
        "#<%s id=%s name=%s>" % [self.class.name, id.inspect, name.inspect]
      end
    end

    # `Place` is a class represents places in PT-net.
    class Place < Node
      member :net
      member :id
      member :name
    end

    # `Transition` is a class represents transitions in PT-net.
    class Transition < Node
      member :net
      member :id
      member :name
    end

    # `Arc` is a class represents arcs in PT-net.
    class Arc < StructX
      member :net
      member :id
      member :source_id
      member :target_id

      # Return true if the arc has the direction from transition to place.
      def from_transition_to_place?
        net.transitions.any? {|t| t.id == source_id} and net.places.any? {|p| p.id == target_id}
      end

      # Return true if the arc has the direction from place to transition.
      def from_place_to_transition?
        net.places.any? {|p| p.id == source_id} and net.transitions.any? {|t| t.id == target_id}
      end

      def inspect
        "#<Pione::PNML::Arc id=%s source_id=%s target_id=%s>" % [id.inspect, source_id.inspect, target_id.inspect]
      end
    end
  end
end
