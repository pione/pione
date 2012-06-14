require 'pione/common'

module Pione
  module Rule
    module FlowElement
      class Base < PioneObject; end

      # CallRule represents the application of a rule.
      # For example of simple rule calling:
      #   rule r1
      #   => CallRule.new(RuleExpr.new('r1'))
      #
      # For example with absolute path:
      #   rule /abc:a
      #   => CallRule.new(RuleExpr.new('/abc:a'))
      #
      # For example with variable:
      #   rule $X
      #   => CallRule.new(Variable.new('X'))
      class CallRule < Base
        attr_reader :expr
        attr_accessor :package

        def initialize(expr)
          @expr = expr
        end

        # Return a rule path with expanding variables.
        def rule_path(vtable=VariableTable.new)
          @expr.eval(vtable)
        end

        # Returns true if sync mode.
        def sync_mode?
          @expr.sync_mode?
        end

        def ==(other)
          @expr == expr
        end

        alias :eql? :==

        # Returns hash value.
        def hash
          @expr.hash
        end
      end

      # ConditionalBlock represents conditional flow applications.
      # For example of /if/ statement:
      #   if $X == "a"
      #     rule r1
      #   else
      #     rule r2
      #   end
      #   => ConditionalBlock.new(Application.new('==', Variable.new('X'), 'a'),
      #                           { true => [CallRule.new('r1')],
      #                             :else => [CallRule.new('r2')] })
      #
      # For example of case statement:
      #   case $X
      #   when "a"
      #     rule r1
      #   when "b"
      #     rule r2
      #   else
      #     rule r3
      #   end
      #   => ConditionalBlock.new(Variable.new('X'),
      #                           { 'a' => [CallRule.new('r1')],
      #                             'b' => [CallRule.new('r2')],
      #                             :else => [CallRule.new('r3')] })
      #
      class ConditionalBlock
        attr_reader :expr
        attr_reader :blocks

        def initialize(expr, blocks)
          @expr = expr
          @blocks = blocks
        end

        # Evaluates the condition and returns the flow block.
        def eval(vtable=VariableTable.new)
          value = @expr.eval(vtable)
          block = @blocks.find {|key, _| key === value}
          block = block[1] unless block.nil?
          block = @blocks[:else] if block.nil?
          block = [] if block.nil?
          return block
        end
      end


      # Assignment represents a value assignment for variable.
      # For example assigning a string:
      #   $X := "a"
      #   => Assignment.new(Variable.new('X'), 'a')
      #
      # For exmpale assigning a variable value:
      #   $X := $Y
      #   => Assignment.new(Variable.new('X'), Variable.new('Y'))
      class Assignment
        attr_reader :variable
        attr_reader :expr

        def initialize(variable, expr)
          @variable = variable
          @expr = expr
        end

        # Evaluates a right value and set it into variable table.
        def eval(vtable)
          vtable.set(@variable, @expr.eval(vtable))
        end
      end
    end
  end
end
