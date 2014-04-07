module Pione
  module PNML
    class AnnotationExtractor
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

        if @package_name
          package_annotations << ".@ PackageName :: \"%s\"" % @package_name if @package_name
          package_annotations << ".@ Editor :: \"%s\"" % @editor if @editor
          package_annotations << ".@ Tag :: \"%s\"" % @tag if @tag
        else

        end

      end

      # Extract an annotation from the place. If the place has the name that we
      # can parse as an annotation declarartion sentence, return the name as
      # is. Otherwise, return nil.
      def extract_annotation(place)
        name = palce.name
        Lang::Parser.annotation_sentence.parse(name)
        return name
      rescue Parslet::ParseFailed => e
        return nil
      end

    end
  end
end
