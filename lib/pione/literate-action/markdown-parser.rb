module Pione
  module LiterateAction
    # MarkdownParser is a parser for literate action document.
    class MarkdownParser
      # Parse the source string and return the result.
      def self.parse(src)
        new(src).parse
      end

      def initialize(src)
        @src = src
      end

      # Parse the source string.
      def parse
        @parsed = Kramdown::Parser::GFM.parse(@src)
        current_name = nil
        root = @parsed.first
        root.children.each_with_object(Hash.new) do |elt, action|
          if name = find_rule_name(elt)
            current_name = name
            next
          end

          if current_name
            lang, content = find_action(elt)
            if content
              action[current_name] ||= {content: ""}
              action[current_name][:lang] = lang
              action[current_name][:content] << content
            end
          end
        end
      end

      private

      # Find a rule name from the document element.
      def find_rule_name(elt)
        if elt.type == :header and elt.options[:level] == 2
          elt.options[:raw_text]
        end
      end

      # Find an action from the document element.
      def find_action(elt)
        if elt.type == :codeblock
          if elt.attr["class"] and elt.attr["class"].start_with?("language-")
            # with language
            return [elt.attr["class"].sub("language-", ""), elt.value]
          else
            # without language
            return [nil, elt.value]
          end
        end
      end
    end
  end
end
