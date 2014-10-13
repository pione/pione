module Pione
  module PNML
    # `Perspective` is a meta class for PIONE's concepts overlayed in PNML.
    class Perspective
      # Return true if the node is empty.
      #
      # @return [Boolean]
      #   true if the node is empty
      def self.empty?(node)
        empty_place?(node) or empty_transition?(node)
      end

      # Return true if the node is an empty place.
      #
      # @return [Boolean]
      #   true if the node is an empty place
      def self.empty_place?(node)
        match_place_parser?(node, :empty_place)
      end

      # Return true if the node is an empty transition.
      #
      # @return [Boolean]
      #   true if the node is an empty transition
      def self.empty_transition?(node)
        match_transition_parser?(node, :empty_transition)
      end

      # Return true if the node is an expression in PIONE.
      def self.expr?(node)
        match_place_parser?(node, :place_expr)
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
        match_place_parser?(node, :place_file)
      end

      # Return true if the node is a net's input file.
      #
      # @param node [PNML::Node]
      #   the node
      # @return [Boolean]
      #   true if the node is a net's input file.
      def self.net_input_file?(node)
        match_place_parser?(node, :place_net_input_file)
      end

      # Return true if the node is a net's output file.
      #
      # @param node [PNML::Node]
      #   the node
      # @return [Boolean]
      #   true if the node is a net's output file.
      def self.net_output_file?(node)
        match_place_parser?(node, :place_net_output_file)
      end

      # Return true if the node is a ticket in PIONE model.
      #
      # @return [Boolean]
      #   true if the node is a ticket
      def self.ticket?(node)
        match_place_parser?(node, :place_ticket)
      end

      # Return true if the node is a parameter.
      #
      # @return [Boolean]
      #   true if the node is a parameter
      def self.param?(node)
        match_place_parser?(node, :place_param)
      end

      # Return true if the node is a net input parameter.
      #
      # @return [Boolean]
      #   true if the node is a net input parameter
      def self.net_input_param?(node)
        match_place_parser?(node, :place_net_input_param)
      end

      # Return true if the node is a rule.
      #
      # @param node [PNML::Node]
      #   the node
      # @return [Boolean]
      #   true if the node is a rule.
      def self.rule?(node)
        return (internal_rule?(node) or external_rule?(node))
      end

      # Return ture if the node is an internal rule.
      #
      # @param [PNML::Node] node
      #   PNML node
      # @return [Boolean]
      #   true if the node is an internal rule
      def self.internal_rule?(node)
        match_transition_parser?(node, :internal_rule)
      end

      # Return ture if the node is an external rule.
      #
      # @param [PNML::Node] node
      #   PNML node
      # @return [Boolean]
      #   true if the node is an external rule
      def self.external_rule?(node)
        match_transition_parser?(node, :external_rule)
      end

      # Normalize the rule name.
      #
      # @param name [String]
      #   rule expression
      # @return [String]
      #   rule expression without modifier and comment
      def self.normalize_rule_name(name)
        return nil if name.nil?

        matched = Parser.new.transition_rule.parse(name)
        offset = matched[:rule_expr].offset
        tail_offset = matched[:tail] ? matched[:tail].offset : name.size
        return name[offset, tail_offset - offset]
      end

      # Normalize the data name.
      #
      # @param name [String]
      #   data expression
      # @return [String]
      #   data expression without modifier and comment
      def self.normalize_data_name(name)
        return nil if name.nil?

        matched = Parser.new.place_file.parse(name)
        offset = find_head_character_position(matched[:expr])
        tail_offset = matched[:tail] ? matched[:tail].offset : name.size
        return name[offset, tail_offset - offset]
      end

      def self.normalize_param(name)
        return nil if name.nil?

        matched = Parser.new.place_param.parse(name)
        offset = find_head_character_position(matched[:param])
        tail_offset = matched[:tail] ? matched[:tail].offset : name.size
        return name[offset, tail_offset - offset]
      end

      # Return modifier of the name.
      #
      # @param name [String]
      #   data expression
      # @return [String]
      #   modifier or nil
      def self.place_modifier(node)
        if node.kind_of?(Place) and not(node.name.nil?)
          begin
            matched = Parser.new.place.parse(node.name)
            if matched.kind_of?(Hash)
              return matched[:place_modifier].to_s
            end
          rescue Parslet::ParseFailed
          end
        end
        return nil
      end

      # Return true if the node is keyword "if".
      #
      # @param node [PNML::Node]
      #   PNML's node
      # @return [Boolean]
      #   true if the node is keyword "if"
      def self.keyword_if?(node)
        match_transition_parser?(node, :transition_if)
      end

      # Return true if the node is keyword "then".
      # @param node [PNML::Node]
      #   PNML's node
      # @return [Boolean]
      #   true if the node is keyword "then"
      def self.keyword_then?(node)
        match_transition_parser?(node, :transition_then)
      end

      # Return true if the node is keyword "else".
      # @param node [PNML::Node]
      #   PNML's node
      # @return [Boolean]
      #   true if the node is keyword "else"
      def self.keyword_else?(node)
        match_transition_parser?(node, :transition_else)
      end

      # Return true if the node is keyword "case".
      # @param node [PNML::Node]
      #   PNML's node
      # @return [Boolean]
      #   true if the node is keyword "case"
      def self.keyword_case?(node)
        match_transition_parser?(node, :transition_case)
      end

      # Return true if the node is keyword "when".
      # @param node [PNML::Node]
      #   PNML's node
      # @return [Boolean]
      #   true if the node is keyword "when"
      def self.keyword_when?(node)
        match_transition_parser?(node, :transition_when)
      end

      # Return true if the node is keyword "constraint".
      # @param node [PNML::Node]
      #   PNML's node
      # @return [Boolean]
      #   true if the node is keyword "constraint"
      def self.keyword_constraint?(node)
        match_transition_parser?(node, :transition_constraint)
      end

      private

      # Return true if the node matches the place parser.
      #
      # @param node [PNML::Node]
      #   PNML's node
      # @param parser_name [String]
      #   place parser name
      # @return [Boolean]
      #   true if the node is the place parser
      def self.match_place_parser?(node, parser_name)
        if node.kind_of?(Place) and not(node.name.nil?)
          begin
            Parser.new.send(parser_name).parse(node.name)
            return true
          rescue Parslet::ParseFailed
          end
        end
        return false
      end

      # Return true if the node matches the transition parser.
      #
      # @param node [PNML::Node]
      #   PNML's node
      # @param parser_name [String]
      #   transition parser name
      # @return [Boolean]
      #   true if the node is the keyword
      def self.match_transition_parser?(node, parser_name)
        if node.kind_of?(Transition) and not(node.name.nil?)
          begin
            Parser.new.send(parser_name).parse(node.name)
            return true
          rescue Parslet::ParseFailed
          end
        end
        return false
      end

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

      # Find position of head character of parsed tree.
      #
      # @param parsed [Hash]
      #   parsed tree
      # @return [Integer]
      #   position of head character or nil
      def self.find_head_character_position(parsed)
        return nil if parsed.nil?

        pos = nil
        parsed.values.each do |value|
          if value.kind_of?(Hash)
            if _pos = find_head_character_position(value)
              if pos.nil? or pos > _pos
                pos = _pos
              end
            end
          else
            if value.kind_of?(Parslet::Slice) and (pos.nil? or pos > value.offset)
              pos = value.offset
            end
          end
        end
        return pos
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
          "{%s}" % [@params.map{|param| "%s: %s" % [param.var, param.value]}.join(", ")]
        end
      end
    end

    # `DataCondition` is a class represents PIONE's input and output data condition.
    class Data < Perspective
      attr_reader :data_expr
      attr_accessor :input_distribution
      attr_accessor :output_distribution
      attr_accessor :priority
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
      def initialize(node)
        unless Perspective.file?(node)
          raise ArgumentError.new("The node %s should be a data." % node)
        end

        @name = Perspective.normalize_data_name(node.name.strip)
        @priority = extract_priority(node.name.strip)
      end

      private

      def textize_data_expr(type)
        data_expr = "%s" % @name
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

      def extract_priority(name)
        matched = Parser.new.data_priority.parse(name)
        return matched[:priority].to_i
      rescue Parslet::ParseFailed
        return nil
      end
    end

    class InputData < Data
      # Return a declaration string of the data expression as input condition.
      def as_declaration(option={})
        indent("input %s" % textize_data_expr(:input), option)
      end
    end

    class OutputData < Data
      # Return a declaration string of the data expression as output condition.
      def as_declaration(option={})
        indent("output %s" % textize_data_expr(:output), option)
      end
    end

    # `Param` is a class represents PIONE's paramter declaration.
    class Param < Perspective
      attr_reader :name
      attr_reader :var
      attr_reader :value

      # @param node [PNML::Node]
      #   parameter name and the default value
      def initialize(node)
        @name = Perspective.normalize_param(node.name)
        parsed = Parser.new.place_param.parse(@name.to_s)
        @var = parsed[:param][:expr1][:variable][:name]
        expr2 = parsed[:param][:expr2]
        expr2_offset = Perspective.find_head_character_position(expr2)
        tail_offset = parsed[:tail] ? parsed[:tail].offset : @name.size
        @value = @name[expr2_offset, tail_offset - expr2_offset]
      end

      def as_declaration(option={})
        indent("param %s" % @name, option)
      end
    end

    # Constraint represents a PIONE's constraint declaration.
    class Constraint < Perspective
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def as_declaration(option={})
        indent("constraint " + @expr, option)
      end
    end

    # Ticket represents a PIONE's ticket declaration.
    class Ticket < Perspective
      attr_reader :name

      def initialize(name)
        @name = name
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
            rule.as_declaration(option.merge(level: option[:level] + 1))
          end.join("\n")

          if @table[:else].empty?
            indent(Util::Indentation.cut(TEMPLATE_IF) % [@condition, branch_then], option)
          else
            branch_else = @table[:else].map do |rule|
              rule.as_declaration(option.merge(level: option[:level] + 1))
            end.join("\n")
            indent(Util::Indentation.cut(TEMPLATE_IF_ELSE) % [@condition, branch_then, branch_else], option)
          end
        when :"case"
          branches = @table.each_with_object([]) do |(val, rules), list|
            list << ((val == :else) ? "else" : "when %s" % val)
            level = (option[:level] || 0) + 1
            list.concat(rules.map{|rule| rule.as_declaration(option.merge(level: level))})
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
      attr_accessor :type
      attr_accessor :inputs
      attr_accessor :outputs
      attr_accessor :params
      attr_accessor :constraints
      attr_accessor :source_tickets
      attr_accessor :target_tickets
      attr_accessor :conditions
      attr_accessor :flow_elements
      attr_accessor :action_content

      def initialize(name, type, is_external, net_name, index, option={})
        @name = name
        @type = type
        @is_external = is_external
        @net_name = net_name
        @index = index
        @inputs = option[:inputs] || []
        @outputs = option[:outputs] || []
        @params = option[:params] || []
        @constraints = option[:constraints] || []
        @source_tickets = option[:source_tickets] || []
        @target_tickets = option[:target_tickets] || []
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

      def external?
        @is_external
      end

      def name
        external? ? generate_wrapper_name(@name) : @name
      end

      # Return the declaration form string.
      def as_declaration(option={})
        expr_source_tickets =
          if @source_tickets.size > 0
            "(%s) ==> " % @source_tickets.map {|ticket| "%s" % ticket.name}.join(" | ")
          else
            ""
          end
        expr_target_tickets =
          if @target_tickets.size > 0
            " ==> (%s)" % @target_tickets.map {|ticket| "%s" % ticket.name}.join(" | ")
          else
            ""
          end
        "rule %s%s%s" % [expr_source_tickets, name, expr_target_tickets]
      end

      # Make rule conditions.
      #
      # @return [Array<String>]
      #   rule condition lines
      def rule_conditions
        conditions = []
        sort_data_list(@inputs).each do |input|
          conditions << input.as_declaration
        end
        sort_data_list(@outputs).each do |output|
          conditions << output.as_declaration
        end
        @params.each do |param|
          conditions << param.as_declaration
        end
        @constraints.each do |constraint|
          conditions << constraint.as_declaration
        end
        conditions
      end

      def sort_data_list(data_list)
        data_list.sort do |a, b|
          priority_a = a.priority
          priority_b = b.priority

          if a.priority and b.priority
            a.priority <=> b.priority
          elsif a.priority
            1
          elsif b.priority
            -1
          else
            0
          end
        end
      end

      def textize
        ERB.new(template, nil, "-").result(binding)
      end

      def template
        if external?
          return Util::Indentation.cut(WRAPPER_TEMPLATE)
        end

        if flow?
          return Util::Indentation.cut(FLOW_RULE_TEMPLATE)
        end

        if @action_content
          return Util::Indentation.cut(LITERATE_ACTION_RULE_TEMPLATE)
        else
          return Util::Indentation.cut(ACTION_RULE_TEMPLATE)
        end
      end

      # Generate a name for wrapper rule.
      def generate_wrapper_name(name)
        "__%s_%s_%s__" % [@net_name, @name, @index]
      end

      FLOW_RULE_TEMPLATE = <<-RULE
        Rule <%= name %>
          <%- rule_conditions.each do |condition| -%>
          <%=   condition %>
          <%- end -%>
        Flow
          <%- @flow_elements.each do |element| -%>
          <%=   element.as_declaration(level: 1) %>
          <%- end -%>
        End
      RULE

      ACTION_RULE_TEMPLATE = <<-RULE
        Rule <%= name %>
          <%- rule_conditions.each do |condition| -%>
          <%=   condition %>
          <%- end -%>
        End
      RULE

      LITERATE_ACTION_RULE_TEMPLATE = <<-RULE
        Rule <%= name %>
          <%- rule_conditions.each do |condition| -%>
          <%=   condition %>
          <%- end -%>
        Action
        <%= Util::Indentation.indent(@action_content, 2) -%>
        End
      RULE

      WRAPPER_TEMPLATE = <<-RULE
        Rule <%= name %>
          <%- rule_conditions.each do |condition| -%>
          <%=   condition %>
          <%- end -%>
        Flow
          rule <%= @name %>
        End
      RULE
    end
  end
end
