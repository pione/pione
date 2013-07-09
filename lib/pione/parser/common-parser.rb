module Pione
  module Parser
    # CommonParser provides a set of symbols, keywords, and utility parsers.
    module CommonParser
      include Parslet

      #
      # symbols
      #

      SYMBOLS = {
        :squote => '\'',
        :dquote => '"',
        :backslash => "\\",
        :dot => '.',
        :comma => ',',
        :lparen => '(',
        :rparen =>')',
        :lbrace => '{',
        :rbrace => '}',
        :slash => '/',
        :plus => '+',
        :minus => '-',
        :question => '?',
        :vbar => '|',
        :ampersand => '&',
        :doller => '$',
        :colon => ':',
        :equals => '=',
        :exclamation => '!',
        :less_than => '<',
        :greater_than => '>',
        :asterisk => '*',
        :percent => '%',
        :atmark => '@',
        :hat => '^',
        :sharp => '#',
        :lsbracket => '[',
        :rsbracket => ']'
      }

      # make symbols
      SYMBOLS.each do |key, val|
        rule(key) { str(val) }
        rule(("%s!" % key).to_sym) { str(val).or_error("it should be '%s'" % val) }
      end

      # +symbols+ matches all symbols in PIONE document.
      rule(:symbols) {
        SYMBOLS.keys.inject(nil) do |res, elt|
          res ? res | send(elt) : send(elt)
        end
      }

      rule(:colon_eq) { colon >> equals }
      rule(:colon_colon) { colon >> colon }

      #
      # keywords
      #

      KEYWORDS = {
        :keyword_Rule => 'Rule',
        :keyword_Flow => 'Flow',
        :keyword_Action => 'Action',
        :keyword_End => 'End',
        :keyword_input => 'input',
        :keyword_output => 'output',
        :keyword_param => 'param',
        :keyword_Param => 'Param',
        :keyword_basic => 'basic',
        :keyword_Basic => 'Basic',
        :keyword_advanced => 'advanced',
        :keyword_Advanced =>  'Advanced',
        :keyword_feature => 'feature',
        :keyword_rule => 'rule',
        :keyword_if => 'if',
        :keyword_else => 'else',
        :keyword_case => 'case',
        :keyword_when => 'when',
        :keyword_end => 'end',
        :keyword_package => 'package',
        :keyword_require => 'require',
        :keyword_true => 'true',
        :keyword_false => 'false',
        :keyword_and => 'and',
        :keyword_or => 'or',
        :keyword_null => 'null',
        :keyword_constraint => 'constraint'
      }

      # make keywords
      KEYWORDS.each do |key, val|
        rule(key) { str(val) }
      end

      #
      # utility parsers
      #

      # +eof+ is parslet version of "End of File".
      rule(:eof) { any.absent? }

      # +newline+ matches newline characters.
      rule(:newline) { str(";") | str("\n") }

      # +comment+ matches comment strings.
      rule(:comment) { str("#") >> (newline.absent? >> any).repeat }

      # +identifier+ matches any sequences excluding space, symbols, and line
      # end.
      rule(:identifier) {
        head = (space | symbols | digit | line_end).absent? >> any
        tail = (space | symbols | line_end).absent? >> any
        special_tail = question | exclamation

        head >> tail.repeat >> special_tail.maybe
      }

      rule(:capital_identifier) {
        head = match("[A-Z]")
        tail = (space | symbols | line_end).absent? >> any
        special_tail = question | exclamation

        head >> tail.repeat >> special_tail.maybe
      }

      # +digit+ matches 0-9.
      rule(:digit) { match('[0-9]') }

      # +space+ matches sequences of space character, tab, or comment.
      rule(:space) { (match("[ \t]") | comment).repeat(1) }

      # +space?+ matches +space+ or empty.
      rule(:space?) { space.maybe }

      # +pad+ matches sequences of space character, tab, newline, or comment.
      rule(:pad) { (match("[ \t\n]") | comment).repeat(1) }

      # +pad?+ matches +pad+ or empty.
      rule(:pad?) { pad.maybe }

      # +line_end+ matches a space sequence until line end.
      rule(:line_end) { space? >> (newline | eof) }

      # +empty_line+ matches an empty line.
      rule(:empty_line) { space? >> newline | space >> eof }
      rule(:empty_line?) { empty_line.maybe }

      # +empty_lines+ matches empty lines.
      rule(:empty_lines) { empty_line.repeat(1) >> eof.maybe }
      rule(:empty_lines?) { empty_lines.maybe }

      #
      # utility methods
      #

      # Enclose the atom by "space?".
      def spaced?(atom)
        space? >> atom >> space?
      end

      # Enclose the atom by "pad?".
      def padded?(atom)
        pad? >> atom >> pad?
      end

      # Create an atom that matches a line with the content.
      def line(content)
        space? >> content >> line_end
      end
    end
  end
end

