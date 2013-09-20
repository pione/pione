module Pione
  module Lang
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

      # make puctuation rules
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
        :keyword_true => 'true',
        :keyword_false => 'false',
        :keyword_and => 'and',
        :keyword_or => 'or',
        :keyword_null => 'null',
        :keyword_constraint => 'constraint',
        :keyword_bind => 'bind'
      }

      # make keywords
      KEYWORDS.each do |key, val|
        rule(key) { str(val) }
      end

      # +keywords+ matches all keywords in PIONE document.
      rule(:keywords) {
        KEYWORDS.keys.inject(nil) do |res, elt|
          res ? res | send(elt) : send(elt)
        end
      }

      #
      # utility parsers
      #

      # +eof+ is parslet version of "End of File".
      rule(:eof) { any.absent? }

      # +newline+ matches newline characters.
      rule(:newline) { str(";") | str("\n") }

      # +binding_operator+ matches operator mark in variable binding declarations or parameter declarations.
      rule(:binding_operator) { colon >> equals }
      rule(:binding_operator!) { binding_operator.or_error("it should be :=") }

      # +generating_operator+ matches operator mark in package binding declarations.
      rule(:generating_operator) { less_than >> minus }
      rule(:generating_operator!) { generating_operator.or_error("it should be <-") }

      # +reverse_message_operator+ matches operator mark of reverse messages.
      rule(:reverse_message_operator) { colon >> colon }
      rule(:reverse_message_operator!) { reverse_message_operator.or_error("it should be ::") }

      # +comment+ matches comment strings.
      rule(:comment) { str("#") >> (newline.absent? >> any).repeat }

      # +identifier+ matches any sequences excluding space, symbols, and line
      # end.
      rule(:identifier) {
        identifier_head_character >> identifier_tail
      }

      rule(:identifier_head_character) {
        (space | symbols | digit | line_end).absent? >> any
      }

      rule(:identifier_tail) {
        identifier_tail_character.repeat >> identifier_special_tail_character.maybe
      }

      rule(:identifier_tail_character) {
        (space | symbols | line_end).absent? >> any
      }

      rule(:identifier_special_tail_character) { question | exclamation }

      rule(:capital_identifier) { match("[A-Z]") >> identifier_tail }
      rule(:small_identifier) { match("[a-z]") >> identifier_tail }

      # +digit+ matches 0-9.
      rule(:digit) { match('[0-9]') }

      # +number+ matches positive/negative numbers.
      rule(:number) { match('[+-]').maybe >> digit.repeat(1) }
      rule(:number!) { number.or_error("it should be number") }

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

