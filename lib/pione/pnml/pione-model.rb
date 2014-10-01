module Pione
  module PNML
    # `Perspective` is a meta class for PIONE's concepts overlayed in PNML.
    class Perspective
      # Eliminate comments from the string. This implementation is temporary, we
      # should fix this.
      def self.eliminate_comment(str)
        # FIXME
        str.sub(/#.*$/, "")
      end

      # Return true if the node is empty in PIONE model.
      #
      # @return [Boolean]
      #   true if the node is empty
      def self.empty?(node)
        # node should be a place or transition
        return false unless node.is_a?(Place) or node.is_a?(Transition)

        return true if node.name.nil?
        return true if /^[<>]?\s*$/.match(eliminate_comment(node.name.strip))
      end

      # Return true if the node is named in PIONE model.
      #
      # @return [Boolean]
      #   true if the node is named
      def self.named?(node)
        not(empty?(node))
      end

      # Return true if the node is a file in PIONE model.
      #
      # @return [Boolean]
      #    true if the node is a file
      def self.file?(node)
        # files should be represented as a place
        return false unless node.is_a?(Place)
        return false if node.name.nil?

        # normalize
        name = node.name.strip
        if name.size > 0 and "<>".include?(name[0])
          name = name.sub(/[<>]/, "")
        end

        # test
        return (name.size > 0 and name[0] == "'")
      end

      # Return true if the node is a ticket in PIONE model.
      #
      # @return [Boolean]
      #   true if the node is a ticket
      def self.ticket?(node)
        # tickets should be represented as a place
        return false unless node.is_a?(Place)

        # try parsing as a ticket expression
        Lang::Parser.ticket_expr.parse(node.name)

        # the node is a ticket
        return true
      rescue Parslet::ParseFailed => e
        # the node is not a ticket
        return false
      end

      # Return true if the node is a parameter in PIONE model.
      #
      # @return [Boolean]
      #   true if the node is a parameter
      def self.param?(node)
        # parameter node should be represented as a place
        return false unless node.is_a?(Place)

        # parameter node should be parsed as a param sentence
        begin
          Lang::DocumentParser.new.param_sentence.parse(name)
          return true
        rescue
          return false
        end
      end

      # Return true if the node is a rule.
      #
      # @param node [PNML::Node]
      #   the node
      # @return [Boolean]
      #   true if the node is a rule.
      def self.rule?(node)
        return false unless node.is_a?(Transition)
        return false unless not(node.name.nil?)

        name = node.name.strip

        # keywords
        if ["if", "else", "then"].include?(name)
          return false
        end

        return name.size > 0
      end

      # Return ture if the node is a flow rule.
      def self.flow_rule?(node)
        rule?(node) and node.name.strip.start_with?("&")
      end

      def self.action_rule?(node)
        rule?(node) and not(flow_rule?(node))
      end

      def self.normalize_data_name(name)
        return nil if name.nil?

        name = name.strip
        name = remove_comment(name)
        if name.size > 0 and name[0] == "<" or name[0] == ">"
          name[1..-1].strip
        else
          name
        end
      end

      def self.compact(name)
        remove_comment(name)
      end

      def self.remove_comment(name)
        name.sub(/#\s*$/, "").strip
      end

      # Return true if the node is a net's input.
      #
      # @param node [PNML::Node]
      #   the node
      # @return [Boolean]
      #   true if the node is a net's input.
      def self.net_input?(node)
        node.name and compact(node.name)[0] == "<"
      end

      # Return true if the node is a net's output.
      #
      # @param node [PNML::Node]
      #   the node
      # @return [Boolean]
      #   true if the node is a net's output.
      def self.net_output?(node)
        node.name and compact(node.name)[0] == ">"
      end

      def self.modifier(name)
        if name.size > 0 and name.strip[0] == "<"
          return "<"
        end
        if name.size > 0 and name.strip[0] == ">"
          return ">"
        end
        return ""
      end

      private

      # Return an indented version of the string. Indentation size is calculated
      # by the optional argument `:level`. If the level is zero, return the
      # string as is.
      #
      # @param option [Hash]
      # @option option [Integer] :level
      #   indentation level, this should be non-negative integer
      def indent(str, option)
        str.lines.map do |line|
          ("  " * (option[:level] || 0)) + line
        end.join
      end
    end

    # `ConstituentRule` is a class represents PIONE's constituent rule.
    class ConstituentRule < Perspective
      attr_reader :type
      attr_reader :name
      attr_reader :params

      # @param type [Symbol]
      #   rule type of either `:input` or `:output`
      # @param name [String]
      #   rule name
      def initialize(type, name)
        @type = type
        @name = name
        @params = []
      end

      # Return a declaration of constituent rule.
      #
      # @return [String]
      #   a declaration string for PIONE's constituent rule
      def as_declaration(option={})
        indent("rule %s" % textize_rule_expr, option)
      end

      private

      # Return a string form of PIONE's rule expression.
      def textize_rule_expr
        [@name, textize_params].compact.join(" ")
      end

      # Return a string form of PIONE's parameter set.
      def textize_params
        unless @params.empty?
          "{%s}" % [@params.map{|param| "%s: $%s" % [param.name, param.name]}.join(", ")]
        end
      end
    end

    # `DataCondition` is a class represents PIONE's input and output data condition.
    class DataCondition < Perspective
      attr_reader :data_expr
      attr_accessor :input_distribution
      attr_accessor :output_distribution
      attr_accessor :input_priority
      attr_accessor :output_priority
      attr_accessor :input_nonexistable
      attr_accessor :output_nonexistable
      attr_accessor :output_for_this_flow

      # @param data_expr [String]
      #   data expression as a PIONE's expression string
      # @param attr [Hash]
      #   various attributes for the data expression
      # @option attr [Symbol] :input_distribution
      #   input distribution type of either `:each` or `:all`
      # @option attr [Symbol] :output_distribution
      #   output distribution type of either `:each` or `:all`
      # @option attr [Integer] :input_priority
      #   priority of this input condition
      # @option attr [Integer] :output_priority
      #   priority of this output condition
      # @option attr [Boolean] :output_for_this_flow
      #   flag for this flow's output
      def initialize(data_expr, attr={})
        @data_expr = data_expr
        @input_distribution = attr[:input_distribution]
        @output_distribution = attr[:output_distribution]
        @input_priority = attr[:input_priority] || 1
        @output_priority = attr[:output_priority] || 1
        @input_nonexistable = attr[:input_nonexistable]
        @output_nonexistable = attr[:output_nonexistable]
        @output_for_this_flow = attr[:output_for_this_flow]
      end

      # Return a declaration string of the data expression as input condition.
      def as_input_declaration(option={})
        indent("input %s" % textize_data_expr(:input), option)
      end

      # Return a declaration string of the data expression as output condition.
      def as_output_declaration(option={})
        indent("output %s" % textize_data_expr(:output), option)
      end

      private

      def textize_data_expr(type)
        data_expr = "%s" % @data_expr
        if (type == :input and @input_nonexistable) or (type == :output and @output_nonexistable)
          data_expr = data_expr + " or null"
        end
        if type == :input and @input_distribution
          data_expr = "(%s).%s" % [data_expr, @input_distribution]
        end
        if type == :output and @output_distribution
          data_expr = "(%s).%s" % [data_expr, @output_distribution]
        end
        return data_expr
      end
    end

    # `Param` is a class represents PIONE's paramter declaration.
    class Param < Perspective
      attr_reader :name
      attr_reader :default_expr

      # @param name [String]
      #   parameter name, note that this name doesn't include heading `$`
      # @param default expr [String]
      #   default value expression
      def initialize(name, default_expr)
        @name = name
        @default_expr = default_expr
      end

      def as_declaration(option={})
        indent("param $%s := %s" % [@name, @default_expr], option)
      end
    end

    # ConditionalBranch is a class represents PIONE's conditional branch
    # declaration.
    class ConditionalBranch < Perspective
      attr_reader :condition
      attr_reader :table

      def initialize(type, condition)
        @type = type
        @condition = condition
        @table = Hash.new {|h,k| h[k] = []}
      end

      def as_declaration(option={})
        case @type
        when :"if"
          branch_then = @table[:then].map do |rule|
            "  rule %s" % Perspective.normalize_data_name(rule.name)
          end.join("\n")

          if @table[:else].empty?
            indent(Util::Indentation.cut(TEMPLATE_IF) % [@condition, branch_then], option)
          else
            branch_else = @table[:else].map do |rule|
              "  rule %s" % Perspective.normalize_data_name(rule.name)
            end.join("\n")
            indent(Util::Indentation.cut(TEMPLATE_IF_ELSE) % [@condition, branch_then, branch_else], option)
          end
        when :"case"
          branches = @table.each_with_object([]) do |(val, rules), list|
            list << ((val == :else) ? "else" : "when %s" % val)
            list.concat(rules.map{|rule| "  rule %s" % rule.name})
          end.join("\n")
          indent(Util::Indentation.cut(TEMPLATE_CASE) % [@condition, branches], option)
        end
      end

      TEMPLATE_IF = <<-TXT
        if %s
        %s
        end
      TXT

      TEMPLATE_IF_ELSE = <<-TXT
        if %s
        %s
        else
        %s
        end
      TXT

      TEMPLATE_CASE = <<-TXT
        case %s
        %s
        end
      TXT
    end

    class RuleDefinition < Perspective
      attr_accessor :name
      attr_accessor :type
      attr_accessor :inputs
      attr_accessor :outputs
      attr_accessor :params
      attr_accessor :conditions
      attr_accessor :flow_elements
      attr_accessor :action_content

      def initialize(name, type, option={})
        @name = name
        @type = type
        @inputs = option[:inputs] || []
        @outputs = option[:outputs] || []
        @params = option[:params] || []
        @conditions = option[:conditions] || []
        @flow_elements = option[:flow_elements] || []
        @action_content = nil
      end

      def flow?
        @type == :flow
      end

      def action?
        @type == :action
      end

      def textize
        if flow?
          template = Util::Indentation.cut(FLOW_RULE_TEMPLATE)
        else
          if @action_content
            template = Util::Indentation.cut(LITERATE_ACTION_RULE_TEMPLATE)
          else
            template = Util::Indentation.cut(ACTION_RULE_TEMPLATE)
          end
        end
        ERB.new(template, nil, "-").result(binding)
      end

      FLOW_RULE_TEMPLATE = <<-RULE
        Rule <%= @name %>
          <%- @inputs.each do |input| -%>
          input <%= input %>
          <%- end -%>
          <%- @outputs.each do |output| -%>
          output <%= output %>
          <%- end -%>
          <%- @params.each do |param| -%>
          <%= param.as_declaration %>
          <%- end -%>
        Flow
          <%- @flow_elements.each do |element| -%>
          <%- if element.is_a?(RuleDefinition) -%>
          rule <%= element.name %>
          <%- else -%>
        <%= element.as_declaration(level: 1) %>
          <%- end -%>
          <%- end -%>
        End
      RULE

      ACTION_RULE_TEMPLATE = <<-RULE
        Rule <%= @name %>
          <%- @inputs.each do |input| -%>
          input <%= input %>
          <%- end -%>
          <%- @outputs.each do |output| -%>
          output (<%= output %>).touch
          <%- end -%>
          <%- @params.each do |param| -%>
          <%= param.as_declaration %>
          <%- end -%>
        End
      RULE

      LITERATE_ACTION_RULE_TEMPLATE = <<-RULE
        Rule <%= @name %>
          <%- @inputs.each do |input| -%>
          input <%= input %>
          <%- end -%>
          <%- @outputs.each do |output| -%>
          output <%= output %>
          <%- end -%>
          <%- @params.each do |param| -%>
          <%= param.as_declaration %>
          <%- end -%>
        Action
        <%= Util::Indentation.indent(@action_content, 2) -%>
        End
      RULE
    end
  end
end
