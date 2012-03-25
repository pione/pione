require 'parslet'
require 'innocent-white/common'
require 'innocent-white/rule'

module InnocentWhite
  class Document < InnocentWhiteObject
    class Definition
      # Evaluate the block in a rule definition context.
      def self.eval(&b)
        obj = new
        obj.instance_eval(&b)
        return obj
      end

      # Create all modified name.
      def all(name)
        DataExp.all(name)
      end

      # Create each modified name.
      def each(name)
        DataExp.each(name)
      end

      # Input statement.
      def inputs(*items)
        @inputs = items.map(&DataExp)
      end

      # Output statement.
      def outputs(*items)
        @outputs = items.map(&DataExp)
      end

      # Parameter statement.
      def params(*items)
        @params = items
      end

      # Content definition.
      def content(s)
        @content = s
      end

      # Create a rule caller.
      def call(rule_path)
        Rule::FlowElement::CallRule.new(rule_path)
      end

      # Add ruby shebang line.
      def ruby(str, charset=nil)
        res = "#!/usr/bin/env ruby\n"
        res << "# -*- coding: #{charset} -*-\n" if charset
        return res + str
      end
    end

    # Flow rule definition.
    class FlowDefinition < Definition
      def to_rule(path)
        Rule::FlowRule.new(path, @inputs, @outputs, @params, @content)
      end
    end

    # Action rule definition.
    class ActionDefinition < Definition
      # Convert to a rule handler.
      def to_rule(path)
        Rule::ActionRule.new(path, @inputs, @outputs, @params, @content)
      end
    end

    # Load a document and return rule table.
    def self.load(file)
      return eval(file.read)
    end

    attr_reader :rules

    def initialize(&b)
      @rules = {}
      instance_eval(&b)
    end

    def flow(name, &b)
      flow = FlowDefinition.eval(&b).to_rule(name)
      @rules[name] = flow
    end

    def action(name, &b)
      action = ActionDefinition.eval(&b).to_rule(name)
      @rules[name] = action
    end

    def [](name)
      @rules[name]
    end
  end
end

class String
  def stdout
    DataExp.new(self).stdout
  end

  def stderr
    DataExp.new(self).stderr
  end
end

module InnocentWhite
  class DocumentParser < Parslet::Parser
    root(:rule_definitions)

    #
    # common
    #

    rule(:line_end) { space? >> str("\n") | any.absent? }
    rule(:dot) { str('.') }
    rule(:comma) { str(',') }
    rule(:lparen) { str('(') }
    rule(:rparen) { str(')') }
    rule(:lbrace) { str('{') }
    rule(:rbrace) { str('}') }
    rule(:space) { match("[ \t]").repeat(1) }
    rule(:space?) { space.maybe }

    rule(:symbols) {
      dot |
      comma |
      lparen |
      rparen |
      lbrace |
      rbrace
    }

    #
    # keyword
    #

    rule(:keyword_rule_header) { str('Rule') }
    rule(:keyword_input) {
      (str('input-all') | str('input')).as(:keyword_input)
    }
    rule(:keyword_output) {
      (str('output-all') | str('output')).as(:keyword_output)
    }
    rule(:keyword_param) { str('param') }
    rule(:keyword_flow_block_begin) { str('Flow') }
    rule(:keyword_action_block_begin) { str('Action') }
    rule(:keyword_block_end) { str('End') }
    rule(:keyword_call_rule) { str('rule') }
    rule(:keyword_if) { str('if') }
    rule(:keyword_else) { str('else') }
    rule(:keyword_case) { str('case') }
    rule(:keyword_when) { str('when') }
    rule(:keyword_end) { str('end') }

    #
    # literal
    #

    rule(:rule_name) {
      (match("[A-Z_]") >>
       ((space | dot | line_end).absent? >> any).repeat
       ).as(:rule_name)
    }

    rule(:data_name) {
      str('\'') >>
      (str('\\') >> any | (str('\'').absent? >> any)).repeat.as(:data_name) >>
      str('\'')
    }

    rule(:string) {
      str('"') >>
      (str('\\') >> any | (str('"').absent? >> any)).repeat.as(:string) >>
      str('"')
    }

    rule(:identifier) {
      match("[a-z_]").repeat(1).as(:identifier)
    }

    rule(:variable) {
      str('$') >> ((space | symbols | line_end).absent? >> any).repeat(1).as(:variable)
    }

    #
    # rule
    #

    rule(:rule_definitions) {
      (space? >> rule_definition >> space?).repeat
    }

    rule(:rule_definition) {
      (rule_header.as(:rule_header) >>
       input_line.repeat(1).as(:inputs) >>
       output_line.repeat(1).as(:outputs) >>
       param_line.repeat.as(:params) >>
       block >>
       any.repeat.as(:rest)
       ).as(:rule)
    }

    rule(:rule_header) {
      keyword_rule_header >> space >> rule_name >> line_end
    }

    #
    # input / output
    #

    rule(:input_line) {
      (space? >>
       keyword_input >>
       space >>
       data_expr.as(:data_expr) >>
       line_end).as(:input_line)
    }

    rule(:output_line) {
      (space? >>
       keyword_output >>
       space >>
       data_expr.as(:data_expr) >>
       line_end).as(:output_line)
    }

    #
    # data_expr
    #

    rule(:expr) {
      data_expr | rule_expr | string
    }

    rule(:data_expr) {
      data_name >> attribution.repeat.as(:attributions)
    }

    rule(:rule_expr) {
      rule_name >> attribution.repeat.as(:attributions)
    }

    rule(:attribution) {
      dot >>
      identifier >>
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
    # param
    #

    rule(:param_line) {
      (space? >> keyword_param >> space >> variable >> line_end).as(:param_line)
    }

    #
    # block
    #

    rule(:block) {
      flow_block | action_block
    }

    rule(:flow_block) {
      (flow_block_begin_line >>
       flow_element.repeat >>
       block_end_line
       ).as(:flow_block)
    }

    rule(:action_block) {
      (action_block_begin_line >>
       any.repeat >>
       block_end_line
       ).as(:action_block)
    }

    rule(:flow_block_begin_line) {
      keyword_flow_block_begin >> str('-').repeat(3) >> line_end
    }

    rule(:action_block_begin_line) {
      keyword_action_block_begin >> str('-').repeat(3) >> line_end
    }

    rule(:block_end_line) {
      str('-').repeat(3) >> keyword_block_end >> line_end
    }

    #
    # flow element
    #

    rule(:flow_element) {
      call_rule_line |
      condition_block
    }

    rule(:call_rule_line) {
      (space? >>
       keyword_call_rule >>
       space? >>
       rule_expr >>
       line_end
       ).as(:call_rule)
    }

    rule(:condition_block) {
      if_block
    }

    rule(:if_block) {
      (if_block_begin >>
       flow_element.repeat.as(:true_exprs) >>
       if_block_else.maybe >>
       if_block_end).as(:if_block)
    }

    rule(:if_block_begin) {
      space? >>
      keyword_if >>
      space? >>
      if_condition >>
      line_end
    }

    rule(:if_condition) {
      lparen >> space? >> ref_variable >> space? >> rparen
    }

    rule(:ref_variable) {
      lbrace >> variable >> rbrace
    }

    rule(:if_block_else) {
      space? >> keyword_else >> line_end >>
      flow_element.repeat.as(:false_exprs)
    }

    rule(:if_block_end) {
      space? >> keyword_end >> line_end
    }

  end

  class SyntaxTreeTransform < Parslet::Transform
    class UnknownAttribution < Exception
      def initialize(t, identifier)
        @t = t
        @identifier = identifier
      end
      def message
        "Unknown identifier '#{@identifier}' in the context of #{@t}"
      end
    end

    #
    # common
    #
    rule(:string => simple(:s)) { s }

    #
    # rule
    #
    rule(:rule => subtree(:ruledef)) {
      name = ruledef[:rule_header][:rule_name]
      inputs = ruledef[:inputs]
      outputs = ruledef[:outputs]
      params = ruledef[:params]
      flow_block = ruledef[:flow_block]
      action_block = ruledef[:action_block]
      if flow_block
        Rule::FlowRule.new(name, inputs, outputs, params, flow_block)
      else
        Rule::ActionRule.new(name, inputs, outputs, params, action_block)
      end
    }

    #
    # input / output
    #

    rule(:input_line => subtree(:input)) {
      data_expr = input[:data_expr]
      if input[:keyword_input] == "input-all"
        data_expr.all
      else
        data_expr
      end
    }

    rule(:output_line => subtree(:output)) {
      data_expr = output[:data_expr]
      if output[:keyword_output] == "output-all"
        data_expr.all
      else
        data_expr
      end
    }

    #
    # param
    #

    rule(:param_line => subtree(:param)) {
      param[:variable].to_s
    }

    #
    # data_expr
    #

    rule(:data_name => simple(:name), :attributions => subtree(:attributions)) {
      elt = DataExp.new(name.to_s)
      attributions.each do |attr|
        identifier = attr[:identifier]
        arguments = attr[:arguments]
        case identifier.to_s
        when "except"
          elt.except(*arguments)
        else
          raise UnknownAttribution.new('data', identifier)
        end
      end
      elt
    }

    #
    # flow block
    #

    rule(:call_rule => subtree(:expr)) {
      rule_name = expr[:rule_name].to_s
      elt = Rule::FlowElement::CallRule.new(rule_name)
      expr[:attributions].each do |attr|
        identifier = attr[:identifier]
        arguments = attr[:arguments]
        case identifier.to_s
        when "sync"
          elt.with_sync
        when "params"
          elt.params = arguments.map{|t| t.to_s}
        else
          raise UnknownAttribution.new('rule', identifier)
        end
      end
      elt
    }

    #
    # condition
    #
    rule(:if_block => subtree(:block)) {
      variable = block[:variable].to_s
      true_exprs = block[:true_exprs]
      false_exprs = block[:false_exprs]
      block = {true => true_exprs, false => false_exprs}
      Rule::FlowElement::Condition.new(variable, block)
    }

  end
end
