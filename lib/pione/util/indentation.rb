module Pione

  module Util
    module Indentation
      # Cut indentations of the text. This function cuts indentation of all lines
      # with the depth of first line's indentation.
      #
      # @param text [String]
      #   the text
      # @return [String]
      #   indentation cutted text
      def self.cut(text)
        line = text.lines.to_a.first
        n = line.length - line.lstrip.length
        n > 0 ? text.gsub(/^[ ]{0,#{n}}/m, "") : text
      end

      # Add Indentation to the text.
      #
      # @param text [String]
      #   the text
      # @param size [Integer]
      #   indentaion size
      # @return [String]
      #   indented text
      def self.indent(text, size)
        text.lines.each_with_object("") do |line, indented|
          indented << " " * size + line
        end
      end
    end
  end
end
