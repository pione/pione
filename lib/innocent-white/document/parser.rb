require 'innocent-white/common'
require 'parslet'

module InnocentWhite
  class Document
    class ParserError < Parslet::ParseFailed
      def initialize(str, expected, source, context)
        @str = str
        @expected = expected
        super(str)
      end

      def message
        "#{@str} #{cause}(expected: #{@expected.join(", ")}, #{@source.pos}"
      end
    end

    class SyntaxError < Parslet::Atoms::Base
      def initialize(msg, expected_elements=[])
        @msg = msg
        @expected_elements = expected_elements
      end

      def try(source, context)
        raise ParserError.new(@msg, @expected_elements, source, context)
      end

      def to_s_inner(prec)
        "SYNTAX_ERROR"
      end
    end

    class Parser < Parslet::Parser
      def syntax_error(msg, expect_elements)
        # raise ParserError.new(msg, expect_elements)
        SyntaxError.new(msg)
      end

      #
      # root
      #

      root(:rule_definitions)

      #
      # common
      #

      rule(:line_end) { space? >> str("\n") | any.absent? }
      rule(:empty_lines) { (space? >> str("\n")).repeat }
      rule(:empty_lines?) { empty_lines.maybe }
      rule(:squote) { str('\'') }
      rule(:dquote) { str('"') }
      rule(:backslash) { str("\\") }
      rule(:dot) { str('.') }
      rule(:comma) { str(',') }
      rule(:lparen) { str('(') }
      rule(:rparen) { str(')') }
      rule(:lbrace) { str('{') }
      rule(:rbrace) { str('}') }
      rule(:slash) { str('/')}
      rule(:space) { match("[ \t]").repeat(1) }
      rule(:space?) { space.maybe }
      rule(:plus) { str('+') }
      rule(:minus) { str('-') }
      rule(:question) { str('?') }
      rule(:vbar) { str('|') }

      rule(:symbols) {
        dot | squote | dquote | backslash | dot | comma |
        lparen | rparen | lbrace | rbrace | slash |
        plus | minus | question | vbar
      }

      rule(:digit) { match('[0-9]') }

      #
      # keyword
      #

      rule(:keyword_rule_header) { str('Rule') }
      rule(:keyword_input) { str('input') }
      rule(:keyword_input_all) { str('input-all') }
      rule(:keyword_output) { str('output') }
      rule(:keyword_output_all) { str('output-all') }
      rule(:keyword_param) { str('param') }
      rule(:keyword_feature) { str('feature') }
      rule(:keyword_flow_block_begin) { str('Flow') }
      rule(:keyword_action_block_begin) { str('Action') }
      rule(:keyword_block_end) { str('End') }
      rule(:keyword_call_rule) { str('rule') }
      rule(:keyword_if) { str('if') }
      rule(:keyword_else) { str('else') }
      rule(:keyword_case) { str('case') }
      rule(:keyword_when) { str('when') }
      rule(:keyword_end) { str('end') }
      rule(:keyword_package) { str('package') }
      rule(:keyword_require) { str('require') }

      #
      # literal
      #

      # data_name
      rule(:data_name) {
        squote >>
        (backslash >> any | squote.absent? >> any).repeat.as(:data_name) >>
        squote
      }

      # string
      rule(:string) {
        dquote >>
        (backslash >> any | dquote.absent? >> any).repeat.as(:string) >>
        dquote
      }

      # variable
      rule(:variable) {
        str('$') >>
        ((space | symbols | line_end).absent? >> any).repeat(1).as(:variable)
      }

      # identifier
      rule(:identifier) {
        ((space | symbols | line_end).absent? >> any).repeat(1)
      }

      # rule_name
      rule(:rule_name) {
        ( slash.maybe >>
          identifier >>
          (slash >> identifier).repeat(0)
          ).as(:rule_name)
      }

      # feature_name
      rule(:feature_identifier) {
        identifier.as(:feature_identifier)
      }

      # attribution_name
      rule(:attribution_name) {
        identifier.as(:attribution_name)
      }

      # package_name
      rule(:package_name) {
        identifier.as(:package_name)
      }

      # integer
      rule(:integer) {
        ( match('[+-]').maybe >>
          digit.repeat(1)
          ).as(:integer)
      }

      # float
      rule(:float) {
        ( match('[+-]').maybe >>
          digit.repeat(1) >>
          dot >>
          digit.repeat(1)
          ).as(:float)
      }

      #
      # document statement
      #

      rule(:document_statements) {
        document_statement.repeat.as(:document_statements)
      }

      # document_statement
      rule(:document_statement) {
        package_line |
        require_line
      }

      # package_line
      rule(:package_line) {
        ( space? >>
          keyword_package >>
          space >>
          package_name >>
          line_end
          ).as(:package)
      }

      # require_line
      rule(:require_line) {
        ( space? >>
          keyword_require >>
          space >>
          package_name >>
          line_end
          ).as(:require)
      }

      #
      # rule
      #

      rule(:rule_definitions) {
        (space? >> rule_definition >> empty_lines?).repeat
      }

      rule(:rule_definition) {
        ( rule_header.as(:rule_header) >>
          input_line.repeat(1).as(:inputs) >>
          output_line.repeat(1).as(:outputs) >>
          param_line.repeat.as(:params) >>
          feature_line.repeat.as(:features) >>
          block
          ).as(:rule_definition)
      }

      rule(:rule_header) {
        keyword_rule_header >> space >> rule_name >> line_end
      }

      #
      # rule conditions
      #

      # input_line
      rule(:input_line) {
        ( space? >>
          input_header >>
          space >>
          data_expr.as(:data) >>
          line_end
          ).as(:input_line)
      }

      # input_header
      rule(:input_header) {
        (keyword_input_all | keyword_input).as(:input_header)
      }

      # output_line
      rule(:output_line) {
        ( space? >>
          output_header >>
          space >>
          data_expr.as(:data) >>
          line_end
          ).as(:output_line)
      }

      # output_header
      rule(:output_header) {
        (keyword_output_all | keyword_output).as(:output_header)
      }

      # param_line
      rule(:param_line) {
        ( space? >>
          keyword_param >>
          space >>
          variable >>
          line_end
          ).as(:param_line)
      }

      # feature_line
      rule(:feature_line) {
        ( space? >>
          keyword_feature >>
          space >>
          ( feature_expr |
            syntax_error("Need feature expression in this context.",
                         ["idenfifier"])
           ) >>
          line_end
          ).as(:feature_line)
      }

      #
      # expression
      #

      rule(:expr) {
        float |
        integer |
        data_expr |
        rule_expr |
        string |
        paren_expr
      }

      rule(:paren_expr) {
        lparen >> expr >> rparen
      }

      rule(:data_expr) {
        (data_name >> attributions?).as(:data_expr)
      }

      rule(:rule_expr) {
        (rule_name >> attributions?).as(:rule_expr)
      }

      rule(:attributions?) {
        attribution.repeat.as(:attributions)
      }

      rule(:attribution) {
        dot >>
        attribution_name >>
        attribution_arguments.maybe
      }

      rule(:attribution_arguments) {
        lparen >>
        space? >>
        attribution_argument_element.repeat.as(:arguments) >>
        space? >>
        rparen
      }

      rule(:attribution_argument_element) {
        expr >> attribution_argument_element_rest.repeat
      }

      rule(:attribution_argument_element_rest) {
        space? >> comma >> space? >> expr
      }

      #
      # feature expression
      #

      rule(:feature_expr) {
        (feature_name >> disjunctions.repeat).as(:feature_expr)
      }

      rule(:disjunctions) {
        vbar >> feature_name
      }

      rule(:feature_name) {
        requisite_feature_name |
        exclusive_feature_name |
        preferred_feature_name
      }

      rule(:requisite_feature_name) {
        (plus >> feature_identifier).as(:requisite_feature_name)
      }

      rule(:exclusive_feature_name) {
        (minus >> feature_identifier).as(:exclusive_feature_name)
      }

      rule(:preferred_feature_name) {
        (question >> feature_identifier).as(:preferred_feature_name)
      }

      #
      # block
      #

      rule(:block) {
        flow_block |
        action_block #|
        #error("Found bad block.", ['flow block', 'action block'])
      }

      rule(:flow_block) {
        (flow_block_begin_line >>
         flow_element.repeat >>
         block_end_line
         ).as(:flow_block)
      }

      rule(:action_block) {
        (action_block_begin_line >>
         (block_end_line.absent? >> any).repeat.as(:body) >>
         block_end_line
         ).as(:action_block)
      }

      rule(:flow_block_begin_line) {
        space? >> keyword_flow_block_begin >> str('-').repeat(3) >> line_end
      }

      rule(:action_block_begin_line) {
        space? >> keyword_action_block_begin >> str('-').repeat(3) >> line_end
      }

      rule(:block_end_line) {
        space? >> str('-').repeat(3) >> keyword_block_end >> line_end
      }

      #
      # flow element
      #

      rule(:flow_element) {
        rule_call_line |
        condition_block #|
        #error('Found a bad flow element',
        #      ['rule_call_line',
        #       'condition_block'])
      }

      rule(:rule_call_line) {
        (space? >>
         keyword_call_rule >>
         space? >>
         rule_expr >>
         line_end
         ).as(:rule_call)
      }

      rule(:condition_block) {
        if_block |
        case_block
      }

      rule(:if_block) {
        (if_block_begin >>
         flow_element.repeat.as(:true_elements) >>
         if_block_else.maybe >>
         if_block_end).as(:if_block)
      }

      rule(:if_block_begin) {
        space? >>
        keyword_if >>
        space? >>
        expr >>
        line_end
      }

      rule(:if_block_else) {
        space? >>
        keyword_else >>
        line_end >>
        flow_element.repeat.as(:else_elements)
      }

      rule(:if_block_end) {
        space? >> keyword_end >> line_end
      }

      rule(:case_block) {
        (case_block_begin >>
         when_block.repeat.as(:when_block) >>
         if_block_else.maybe >>
         if_block_end
         ).as(:case_block)
      }

      rule(:case_block_begin) {
        space? >>
        keyword_case >>
        space? >>
        expr >>
        line_end
      }

      rule(:when_block) {
        when_block_begin >>
        flow_element.repeat.as(:elements)
      }

      rule(:when_block_begin) {
        space? >>
        keyword_when >>
        space? >>
        expr.as(:when) >>
        line_end
      }

    end
  end
end
