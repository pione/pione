module Pione
  module Parser
    # CommonParser is a set of symbols, keywords, and utility parsers.
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
      end

      # @!attribute [r] symbols
      #   +symbols+ matches all symbols in PIONE document.
      #   @return [Parslet::Atoms::Entity] +symbols+ atom
      rule(:symbols) {
        SYMBOLS.keys.inject(nil) do |res, elt|
          res ? res | send(elt) : send(elt)
        end
      }

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
        :keyword_null => 'null'
      }

      # make keywords
      KEYWORDS.each do |key, val|
        rule(key) { str(val) }
      end

      #
      # utilities
      #

      # @!attribute [r] identifier
      #   +identifier+ matches any sequences excluding space, symbols, and
      #     line end.
      #   @return [Parslet::Atoms::Entity] +identifier+ atom
      rule(:identifier) {
        ((space | symbols | line_end).absent? >> any).repeat(1) >> question.maybe
      }

      # @!attribute [r] digit
      #   +digit+ matches 0-9.
      #   @return [Parslet::Atoms::Entity] +digit+ atom
      rule(:digit) { match('[0-9]') }

      # @!method space
      #
      # Return +space+ parser. +space+ matches sequences of space character,
      # tab, or comment.
      #
      # @return [Parslet::Atoms::Entity] +space+ atom
      rule(:space) {
        ( match("[ \t]") |
          str("#") >> ((str("\n") | any.absent?).absent? >> any).repeat
        ).repeat(1)
      }

      # @!method space?
      #
      # Return +space?+ parser. +space?+ matches +space+ or empty.
      #
      # @return [Parslet::Atoms::Entity]
      #   +space?+ parser
      rule(:space?) { space.maybe }

      # @!method pad
      #
      # Return +pad+ parser. +pad+ matches sequences of space character, tab,
      # newline, or comment.
      #
      # @return [Parslet::Atoms::Entity]
      #   +pad+ parser
      rule(:pad) {
        ( match("[ \t\n]") |
          str("#") >> ((str("\n") | any.absent?).absent? >> any).repeat
        ).repeat(1)
      }

      # @!method pad?
      #
      # Return +pad?+ parser. +pad?+ matches +pad+ or empty.
      #
      # @return [Parslet::Atoms::Entity]
      #   +pad?+ parser
      rule(:pad?) { pad.maybe }

      # @!attribute [r] line_end
      #   +line_end+ matches a space sequence until line end.
      #   @return [Parslet::Atoms::Entity] +line_end+ atom
      rule(:line_end) { space? >> (str("\n") | any.absent?) }

      # @!attribute [r] empty_lines
      #   +empty_line+ matches empty lines.
      #   @return [Parslet::Atoms::Entity] +empty_line+ atom
      rule(:empty_lines) {
        (space? >> str("\n")).repeat(1) >>
        (space? >> any.absent?).maybe
      }

      # @!attribute [r] empty_lines?
      #   +empty_lines?+ matches empty lines or empty.
      #   @return [Parslet::Atoms::Entity] empty_line? atom
      rule(:empty_lines?) { empty_lines.maybe }
    end
  end
end

