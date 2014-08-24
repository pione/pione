module Pione
  module PNML
    class AnnotationExtractor
      def initialize(net, option)
        @net = net
        @flow_name = option[:flow_name] || "Main"
        @package_name = option[:package_name]
        @editor = option[:editor]
        @tag = option[:tag]
      end

      # Extract annotations from transitions. If the transition has the name
      # that we can parse as an annotation declarartion sentence, return the
      # name as is. Otherwise, return nil.

      # Extract annotations from transitions.
      def extract
        package_annotations = []

        @net.transitions.each do |transition|
          if line = extract_annotation(transition)
            package_annotations << line
          end
        end

        package_annotations << ".@ PackageName :: \"%s\"" % @package_name if @package_name
        package_annotations << ".@ Editor :: \"%s\"" % @editor if @editor
        package_annotations << ".@ Tag :: \"%s\"" % @tag if @tag

        return package_annotations
      end

      private

      # Extract an annotation from the transition. If the transition has the
      # name that we can parse as an annotation declarartion sentence, return
      # the name as is. Otherwise, return nil.
      def extract_annotation(transition)
        name = transition.name
        Lang::DocumentParser.new.annotation_sentence.parse(name)
        return name
      rescue Parslet::ParseFailed => e
        return nil
      end
    end
  end
end
