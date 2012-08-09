module Pione
  class Parser
    module Common
      include Parslet

      #
      # symbols
      #

      SYMBOLS = {
        :squote => '\'',
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

      # make all symbols rule
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

      # identifier
      rule(:identifier) {
        ((space | symbols | line_end).absent? >> any).repeat(1)
      }

      # digit
      rule(:digit) { match('[0-9]') }

      # space
      rule(:space) { match("[ \t]").repeat(1) }

      # space?
      rule(:space?) { space.maybe }

      # pad
      rule(:pad) { match("[ \t\n]").repeat(1) }

      # pad?
      rule(:pad?) { pad.maybe }

      # line_end
      rule(:line_end) { space? >> (str("\n") | any.absent?) }

      # empty_lines
      rule(:empty_lines) {
        (space? >> str("\n")).repeat(1) >>
        (space? >> any.absent?).maybe
       }

      # empty_lines?
      rule(:empty_lines?) { empty_lines.maybe }
    end
  end
end
