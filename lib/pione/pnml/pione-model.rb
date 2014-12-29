module Pione
  module PNML
    # `Perspective` is a meta class for PIONE's concepts overlayed in PNML.
    class Perspective
      TRANSFORMER_OPT = {package_name: "", editor: "", tag: "", filename: ""}

      class << self
        # Return true if the node is empty.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is empty
        def empty?(env, node)
          empty_place?(env, node) or empty_transition?(env, node)
        end

        # Return true if the node is an empty place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is an empty place
        def empty_place?(env, node)
          match_place_parser?(env, node, :empty_place)
        end

        # Return true if the node is an empty transition.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is an empty transition
        def empty_transition?(env, node)
          match_transition_parser?(env, node, :empty_transition)
        end

        # Return true if the node is an expression place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is an exression place
        def expr_place?(env, node)
          match_place_parser?(node, :expr_place)
        end

        # Return true if the node is a data place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #    true if the node is a data place
        def data_place?(env, node)
          match_place_parser_with_type?(env, node, :data_place, :expr, Lang::TypeDataExpr)
        end

        # Return true if the node is a net input data place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a net input data place
        def net_input_data_place?(env, node)
          if data_place?(env, node)
            return net_input_data_symbol?(data_modifier(env, node))
          else
            return false
          end
        end

        # Return true if the node is a net output data place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a net output data place
        def net_output_data_place?(env, node)
          if data_place?(env, node)
            return net_output_data_symbol?(data_modifier(node))
          else
            return false
          end
        end

        # Return true if the node is a parameter.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a parameter
        def param_place?(env, node)
          match_place_parser?(env, node, :param_place)
        end

        # Return true if the node is a parameter sentence transition.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a parameter sentence transition
        def param_transition?(env, node)
          match_transition_parser?(env, node, :param_sentence)
        end

        # Evaluate the node as a parameter sentence.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Object]
        #   evaluated result
        def eval_param_sentence(env, node)
          eval_transition(env, node, :param_sentence, :param_sentence)
        end

        # Return true if the node is a ticket place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a ticket place
        def ticket_place?(env, node)
          match_place_parser_with_type?(env, node, :expr_place, :expr, Lang::TypeTicketExpr)
        end

        # Return true if the node is a feature place.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a feature place
        def feature_place?(env, node)
          match_place_parser_with_type?(env, node, :expr_place, :expr, Lang::TypeFeature)
        end

        # Return true if the node is a feature transition.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a feature transition
        def feature_transition?(env, node)
          match_place_parser?(env, node, :feature_sentence)
        end

        # Return true if the node is a variable binding transition.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a variable binding transition
        def variable_binding_transition?(env, node)
          match_transition_parser?(env, node, :variable_binding_sentence)
        end

        # Return true if the node is a rule.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [Boolean]
        #   true if the node is a rule.
        def rule_transition?(env, node)
          match_transition_parser?(env, node, :rule_transition)
        end

        # Return ture if the node is an internal rule.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param [PNML::Node] node
        #   PNML node
        # @return [Boolean]
        #   true if the node is an internal rule
        def internal_rule_transition?(env, node)
          match_transition_parser?(env, node, :internal_rule_transition)
        end

        # Return ture if the node is an external rule.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param [PNML::Node] node
        #   PNML node
        # @return [Boolean]
        #   true if the node is an external rule
        def external_rule_transition?(env, node)
          match_transition_parser?(env, node, :external_rule_transition)
        end

        # Return the modifier of node name.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   the node
        # @return [String]
        #   modifier or nil
        def data_modifier(env, node)
          if node.kind_of?(Place) and not(node.name.nil?)
            begin
              parsed = Parser.new.data_place.parse(node.name)
              if parsed.kind_of?(Hash)
                return parsed[:modifier].to_s
              end
            rescue Parslet::ParseFailed
              begin
                parsed = Parser.new.empty_place.parse(node.name)
                if parsed.kind_of?(Hash)
                  return parsed[:modifier].to_s
                end
              rescue Parslet::ParseFailed
              end
            end
          end
          return nil
        end

        # Return true if the node is a transition with keyword.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword
        def keyword_transition?(env, node)
          match_transition_parser?(env, node, :keyword_transition)
        end

        # Return true if the node is a transition with keyword "if".
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword "if"
        def if_transition?(env, node)
          match_transition_parser?(env, node, :if_transition)
        end

        # Return true if the node is a transition with keyword "then".
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword "then"
        def then_transition?(env, node)
          match_transition_parser?(env, node, :then_transition)
        end

        # Return true if the node is a transition with keyword "else".
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword "else"
        def else_transition?(env, node)
          match_transition_parser?(env, node, :else_transition)
        end

        # Return true if the node is a transition with keyword "case".
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword "case"
        def case_transition?(env, node)
          match_transition_parser?(env, node, :case_transition)
        end

        # Return true if the node is a transition with keyword "when".
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword "when"
        def when_transition?(env, node)
          match_transition_parser?(env, node, :when_transition)
        end

        # Return true if the node is a transition with keyword "constraint".
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @return [Boolean]
        #   true if the node is a transition with keyword "constraint"
        def constraint_transition?(env, node)
          match_transition_parser?(env, node, :constraint_transition)
        end

        private

        # Return true if the string is net input data symbol.
        #
        # @param [String]
        #   string
        # @return [Boolean]
        #   true if the string is net input data symbol
        def net_input_data_symbol?(str)
          return false if str.nil?

          Parser.new.net_input_symbol.parse(str)
          return true
        rescue Parslet::ParseFailed
          return false
        end

        # Return true if the string is net output data symbol.
        #
        # @param [String]
        #   string
        # @return [Boolean]
        #   true if the string is net output data symbol
        def net_output_data_symbol?(str)
          return false if str.nil?

          Parser.new.net_output_symbol.parse(str)
          return true
        rescue Parslet::ParseFailed
          return false
        end

        # Return true if the node matches the place parser.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @param parser_name [String]
        #   place parser name
        # @return [Boolean]
        #   true if the node is the place parser
        def parse_place(env, node, parser_name)
          if node.kind_of?(Place) and not(node.name.nil?)
            begin
              return Parser.new.send(parser_name).parse(node.name)
            rescue Parslet::ParseFailed
            end
          end
        end

        # Return true if the node matches the place parser.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @param parser_name [String]
        #   place parser name
        # @return [Boolean]
        #   true if the node is the place parser
        def match_place_parser?(env, node, parser_name)
          parsed = parse_place(env, node, parser_name)
          if not(parsed.nil?)
            if block_given?
              return yield parsed
            else
              return true
            end
          else
            return false
          end
        end

        # Return true if the node matches the place parser and expected type.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @param parser_name [String]
        #   place parser name
        # @param target_name [Symbol]
        #   target name that has expected type
        # @param expected_type [Pione::Lang::Type]
        #   expected PIONE type
        # @return [Boolean]
        #   true if the node is the place parser
        def match_place_parser_with_type?(env, node, parser_name, target_name, expected_type)
          parsed = parse_place(env, node, parser_name)
          if parsed and parsed[target_name]
            expr = Lang::DocumentTransformer.new.apply(parsed[target_name], TRANSFORMER_OPT)
            return expr.pione_type(env) == expected_type
          else
            return false
          end
        end

        # Return true if the node matches the transition parser.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @param parser_name [Symbol]
        #   place parser name
        # @return [Boolean]
        #   true if the node is the transition parser
        def parse_transition(env, node, parser_name)
          if node.kind_of?(Transition) and not(node.name.nil?)
            begin
              return Parser.new.send(parser_name).parse(node.name)
            rescue Parslet::ParseFailed
            end
          end
        end

        # Return true if the node matches the transition parser.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @param parser_name [Symbol]
        #   transition parser name
        # @return [Boolean]
        #   true if the node is the keyword
        def match_transition_parser?(env, node, parser_name)
          not(parse_transition(env, node, parser_name).nil?)
        end

        # Evaluate the transition and return the result.
        #
        # @param env [Lang::Environment]
        #   language environment
        # @param node [PNML::Node]
        #   PNML's node
        # @param parser_name [Symbol]
        #   place parser name
        # @param target_name [Symbol]
        #   target name that has expected type
        # @param expected_type [Pione::Lang::Type]
        #   expected PIONE type
        # @return [Boolean]
        #   true if the node is the place parser
        def eval_transition(env, node, parser_name, target_name)
          parsed = parse_transition(node)
          if parsed and parsed[target_name]
            return Lang::DocumentTransformer.new.apply(parsed[target_name], TRANSFORMER_OPT)
          else
            return nil
          end
        end
      end
    end

    class PioneModel
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

    # ConstituentRule is a class represents PIONE's constituent rule.
    class ConstituentRule < PioneModel
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

      # Return a string of rule expression.
      #
      # @return [String]
      #   a string of rule expression
      def textize_rule_expr
        [@name, textize_params].compact.join(" ")
      end

      # Return a string of parameter set.
      #
      # @return [String]
      #   a string of parameter set
      def textize_params
        unless @params.empty?
          @params.inject(Param.new){|res, param| res + param}.as_expr
        end
      end
    end

    # `DataCondition` is a class represents PIONE's input and output data condition.
    class Data < PioneModel
      attr_reader :data_expr
      attr_accessor :input_distribution
      attr_accessor :output_distribution
      attr_accessor :priority
      attr_accessor :input_nonexistable
      attr_accessor :output_nonexistable
      attr_accessor :output_for_this_flow

      # @param nod [PNML::Node]
      #   data expression as a PIONE's expression string
      def initialize(node)
        @name = LabelExtractor.extract_data_expr(node.name)
        @priority = LabelExtractor.extract_priority(node.name)
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

    # Param is a class represents PIONE's paramter set.
    class Param < PioneModel
      # Create a parameter from the parameter set node.
      #
      # @param node [PNML::Node]
      #   parameter set node
      # @return [Param]
      #   parameter
      def self.set_of(node)
        new(LabelExtractor.extract_data_from_param_set(node.name))
      end

      # Create a parameter from the parameter sentence node.
      #
      # @param node [PNML::Node]
      #   parameter sentence node
      # @return [Param]
      #   parameter
      def self.sentence_of(node)
        new(LabelExtractor.extract_data_from_param_sentence(node.name))
      end

      attr_reader :data

      # @param data [Hash]
      #   param set data
      def initialize(data={})
        @data = data
      end

      def as_expr
        @data.map do |var, expr|
          "%s: %s" % [var, expr]
        end.join(", ").tap {|x| return "{%s}" % x}
      end

      def as_declarations(option={})
        @data.map do |var, expr|
          indent("param $%s := %s" % [var, expr], option)
        end
      end

      def +(other)
        self.class.new(@data.merge(other.data))
      end
    end

    # Constraint represents a PIONE's constraint declaration.
    class Constraint < PioneModel
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def as_declaration(option={})
        indent("constraint " + @expr, option)
      end
    end

    # Ticket represents a PIONE's ticket declaration.
    class Ticket < PioneModel
      attr_reader :name

      def initialize(name)
        @name = name
      end
    end

    # Feature represents a feature declaration in PIONE.
    class Feature < PioneModel
      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def as_declaration(option={})
        indent("feature " + @expr, option)
      end
    end

    # ConditionalBranch is a class represents PIONE's conditional branch
    # declaration.
    class ConditionalBranch < PioneModel
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
          branches = @table.each_with_object([]) do |(val, rules), lines|
            lines << ((val == :else) ? "else" : "when %s" % val)
            level = (option[:level] || 0) + 1
            lines.concat(rules.map{|rule| rule.as_declaration(option.merge(level: level))})
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

    class RuleDefinition < PioneModel
      attr_accessor :type
      attr_accessor :inputs
      attr_accessor :outputs
      attr_accessor :params
      attr_accessor :constraints
      attr_accessor :features
      attr_accessor :source_tickets
      attr_accessor :target_tickets
      attr_accessor :conditions
      attr_accessor :variable_bindings
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
        @features = option[:features] || []
        @source_tickets = option[:source_tickets] || []
        @target_tickets = option[:target_tickets] || []
        @variable_bindings = option[:variable_bindings] || []
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
          conditions += param.as_declarations
        end
        @constraints.each do |constraint|
          conditions << constraint.as_declaration
        end
        @features.each do |feature|
          conditions << feature.as_declaration
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
