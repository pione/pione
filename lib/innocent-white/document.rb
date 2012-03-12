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

    rule(:rule_definitions) {
      (space? >> rule_definition.as(:rule) >> space?).repeat
    }

    rule(:rule_definition) {
      (flow_rule | action_rule)
    }

    rule(:flow_rule) {
      flow_rule_header.as(:flow_rule) >>
      input_line.repeat(1).as(:inputs) >>
      output_line.repeat(1).as(:outputs) >>
      param_line.repeat.as(:params) >>
      flow_block.as(:flow_block) >>
      any.repeat.as(:rest)
    }

    rule(:action_rule) {
      action_rule_header >>
      input_line.repeat(1) >>
      output_line.repeat(1) >>
      param_line.repeat >>
      action_block
    }

    rule(:line_end) {
      space? >> str("\n") | any.absent?
    }

    rule(:flow_rule_header) {
      str('Flow') >> space >> name >> line_end
    }

    rule(:action_rule_header) {
      str('Action') >> space >> name >> line_end
    }

    rule(:name) {
      str('\'') >>
      (str('\\') >> any | (str('\'').absent? >> any)).repeat.as(:name) >>
      str('\'')
    }

    rule(:identifier) {
      match("[a-z_]").repeat(1).as(:identifier)
    }

    rule(:input_line) {
      (space? >>
       (str('input-all') | str('input')).as(:type) >>
       space >>
       expr.as(:data_exp) >>
       line_end).as(:input_line)
    }

    rule(:output_line) {
      space? >> str('output') >> space >> expr >> line_end
    }

    rule(:expr) {
      (name >> attribution.repeat.as(:attribution)).as(:expr)
    }

    rule(:attribution) {
      dot >>
      identifier >>
      attribution_arguments.maybe
    }

    rule(:dot) {
      str('.')
    }

    rule(:comma) {
      str(',')
    }

    rule(:attribution_arguments) {
      begin_arguments >>
      space? >>
      attribution_argument_elements.repeat.as(:arguments) >>
      space? >>
      end_arguments
    }

    rule(:begin_arguments) {
      str('(')
    }

    rule(:attribution_argument_elements) {
      attribution_argument_element >> attribution_argument_element_rest.repeat
    }

    rule(:attribution_argument_element) {
      expr
    }

    rule(:attribution_argument_element_rest) {
      space? >> comma >> space? >> expr
    }

    rule(:end_arguments) {
      str(')')
    }

    rule(:param_line) {
      str('param') >> space >> param_name >> line_end
    }

    rule(:param_name) {
      match('[A-Z_]').repeat(1)
    }

    rule(:block_begin_line) {
      match('[A-Z]') >> match('[A-Za-z]').repeat >> str('-').repeat(2) >> line_end
    }

    rule(:block_end_line) {
      str('-').repeat(2) >> match('[A-Z]') >> match('[A-Za-z]').repeat >> line_end
    }

    rule(:flow_block) {
      block_begin_line >>
      flow_element.repeat >>
      block_end_line
    }

    rule(:flow_element) {
      call_rule_line.as(:call_rule)
    }

    rule(:call_rule_line) {
      space? >> str('rule') >> space? >> expr >> line_end
    }

    rule(:action_block) {
      block_begin_line >> any_chars >> block_end_line
    }

    rule(:space) {
      match("[ \t]").repeat(1)
    }

    rule(:space?) {
      space.maybe
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

    rule(:name => simple(:s)) { s.to_s }

    rule(:name => simple(:s), :x => simple(:x)) { s + x }

    rule(:expr => subtree(:x)) { x }

    rule(:data_exp => subtree(:x)) {
      puts "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
      elt = DataExp.new(expr[:name].to_s, @modifier)
      expr[:attribution].each do |attr|
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

    rule(:input_line => {:type => simple(:input), :data_exp => simple(:data)}) {
      @modifier = input.to_s == "input-all" ? :all : :each
      p data
      # expr = input[:expr]
      # elt = DataExp.new(expr[:name].to_s, @modifier)
      # expr[:attribution].each do |attr|
      #   identifier = attr[:identifier]
      #   arguments = attr[:arguments]
      #   case identifier.to_s
      #   when "except"
      #     elt.except(*arguments)
      #   else
      #     raise UnknownAttribution.new('input', identifier)
      #   end
      # end
      # elt
    }

    rule(:call_rule => subtree(:expr)) {
      elt = Rule::FlowElement::CallRule.new(expr[:name].to_s)
      expr[:attribution].each do |attr|
        identifier = attr[:identifier]
        case identifier.to_s
        when "sync"
          elt.with_sync
        else
          raise UnknownAttribution.new('rule', identifier)
        end
      end
      elt
    }
  end
end
