class Pione::Parser
  # Common is a set of common parsers: symbols, keywords, and utility parsers.
  module Common
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
      :keyword_or => 'or'
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
      ((space | symbols | line_end).absent? >> any).repeat(1)
    }

    # @!attribute [r] digit
    #   +digit+ matches 0-9.
    #   @return [Parslet::Atoms::Entity] +digit+ atom
    rule(:digit) { match('[0-9]') }

    # @!attribute [r] space
    #   +space+ matches sequences of space character or tab.
    #   @return [Parslet::Atoms::Entity] +space+ atom
    rule(:space) { match("[ \t]").repeat(1) }

    # @!attribute [r] space?
    #   +space?+ matches +space+ atom or empty.
    #   @return [Parslet::Atoms::Entity] +space?+ atom
    rule(:space?) { space.maybe }

    # @!attribute [r] pad
    #   +space?+ matches space character, tab, and newline.
    #   @return [Parslet::Atoms::Entity] +pad+ atom
    rule(:pad) { match("[ \t\n]").repeat(1) }

    # @!attribute [r] pad?
    #   +space?+ matches +pad+ atom or empty.
    #   @return [Parslet::Atoms::Entity] +pad?+ atom
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
