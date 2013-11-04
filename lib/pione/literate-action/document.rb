module Pione
  module LiterateAction
    class Document
      def self.load(location)
        new(location.read)
      end

      def initialize(src)
        @action = Parser.parse(src)
      end

      # Return action names in the document.
      def action_names
        @action.keys
      end

      # Find target action fromt the name.
      def find(name)
        if action = @action[name]
          Handler.new(action)
        end
      end
    end
  end
end
