module Pione
  module LiterateAction
    class Document
      # Load a literate document from the location.
      def self.load(location)
        new(location.read)
      end

      def initialize(src)
        @action = MarkdownParser.parse(src)
      end

      # Return action rule names in the document.
      #
      # @return [Array<String>]
      #   rule names
      def action_names
        @action.keys
      end

      # Find target action by the name.
      def find(name)
        if action = @action[name]
          Handler.new(action)
        end
      end
    end
  end
end
