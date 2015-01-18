module Pione
  module PNML
    # TicketInstantiation is a net rewriting rule for ticket operation
    # ">>>". This rule replaces anonymous ticket operations into named tickets.
    # Net like this
    #
    #    A --> >>> --> B
    #
    # is replaced
    #
    #    A --> ticket <__TICKET_FROM_A_TO_B__> --> B
    #
    module TicketInstantiation
      TICKET_NAME = "__TICKET_FROM_%s_TO_%s__"

      def self.find_subjects(net, env)
        net.places.each do |place|
          next unless place.name.strip == ">>>"

          net.find_all_transitions_by_target_id(place.id) do |transition_from|
            net.find_all_transitions_by_source_id(place.id) do |transition_to|
              return [transition_from, transition_to, place]
            end
          end
        end

        return nil
      end

      # Rewrite the net with subjects by the following way.
      #
      # - Change the place name
      def self.rewrite(net, subjects, env)
        transition_from, transition_to, place = subjects
        name_from = LabelExtractor.extract_rule_expr(transition_from.name)
        name_to = LabelExtractor.extract_rule_expr(transition_to.name)

        place.name = "<%s>" % (TICKET_NAME % [name_from, name_to])
      end
    end
  end
end
