module InnocentWhite
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
        :doller => '$'
      }

      SYMBOLS.each do |key, val|
        rule(key) { str(val) }
      end

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
        :keyword_input_all => 'input-all',
        :keyword_output => 'output',
        :keyword_output_all => 'output-all',
        :keyword_param => 'param',
        :keyword_feature => 'feature',
        :keyword_rule => 'rule',
        :keyword_if => 'if',
        :keyword_else => 'else',
        :keyword_case => 'case',
        :keyword_when => 'when',
        :keyword_end => 'end',
        :keyword_package => 'package',
        :keyword_require => 'require'
      }

      KEYWORDS.each do |key, val|
        rule(key) { str(val) }
      end

      #
      # utilities
      #

      rule(:digit) { match('[0-9]') }
      rule(:space) { match("[ \t]").repeat(1) }
      rule(:space?) { space.maybe }
      rule(:line_end) { space? >> (str("\n") | any.absent?) }
      rule(:empty_lines) {
        (space? >> str("\n")).repeat(1) >>
        (space? >> any.absent?).maybe
       }
      rule(:empty_lines?) { empty_lines.maybe }
    end
  end
end
