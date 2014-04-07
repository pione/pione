module Pione
  module PNML
    class Reader
      # Read a PNML file at the location and return `PNML::Net`.
      #
      # @param location [Location::DataLocation]
      #   PNML file's location
      def self.read(location)
        new(location.read).read
      end

      def initialize(src)
        @doc = REXML::Document.new(src)
      end

      def read
        Net.new.tap do |net|
          net.transitions = find_transitions(@doc, net)
          net.places = find_places(@doc, net)
          net.arcs = find_arcs(@doc, net)
        end
      end

      # Find all transtions in the document.
      def find_transitions(doc, net)
        REXML::XPath.match(doc, "/pnml/net/transition").map do |elt|
          id = elt.attribute("id").value
          name = REXML::XPath.first(elt, "name/text").texts.map{|text| text.value}.join("")
          Transition.new(net, id, name)
        end
      end

      def find_places(doc, net)
        REXML::XPath.match(doc, "/pnml/net/place").map do |elt|
          id = elt.attribute("id").value
          name = REXML::XPath.first(elt, "name/text").texts.map{|text| text.value}.join("")
          Place.new(net, id, name)
        end
      end

      def find_arcs(doc, net)
        REXML::XPath.match(doc, "/pnml/net/arc").map do |elt|
          id = elt.attribute("id").value
          source_id = elt.attribute("source").value # source place(data) id
          target_id = elt.attribute("target").value # target transition(rule) id
          Arc.new(net, id, source_id, target_id)
        end
      end
    end
  end
end
