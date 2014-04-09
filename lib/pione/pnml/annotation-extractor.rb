module Pione
  module PNML
    class AnnotationExtractor
      def initialize(net, option)
        @net = net
        @flow_name = option[:flow_name] || "Main"
        @package_name = option[:package_name]
        @editior = option[:editor]
        @tag = option[:tag]
      end

      # Extract an annotation from the place. If the place has the name that we
      # can parse as an annotation declarartion sentence, return the name as
      # is. Otherwise, return nil.

      # Extract annotations from places.
      def extract
        package_annotations = []

        @net.places.each do |place|
          if line = extract_annotation(place)
            package_annotations << line
          end
        end

        package_annotations << ".@ PackageName :: \"%s\"" % @package_name if @package_name
        package_annotations << ".@ Editor :: \"%s\"" % @editor if @editor
        package_annotations << ".@ Tag :: \"%s\"" % @tag if @tag

        return package_annotations
      end

      private

      # Extract an annotation from the place. If the place has the name that we
      # can parse as an annotation declarartion sentence, return the name as
      # is. Otherwise, return nil.
      def extract_annotation(place)
        name = place.name
        Lang::DocumentParser.new.annotation_sentence.parse(name)
        return name
      rescue Parslet::ParseFailed => e
        return nil
      end
    end
  end
end
