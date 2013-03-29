module Pione
  module Model
    # ActionBlock represents content script of action.
    #
    # @example
    #   Action
    #     echo "abc"
    #   End
    #   #=> ActionBlock.new("  echo \"abc\"")
    class ActionBlock < BasicModel
      attr_reader :content

      # Create an action block.
      #
      # @param content [String]
      #   action content of shell script
      def initialize(content)
        @content = content
        super()
      end

      # Evaluate the block. Variables of the content is expanded by the variable
      # table.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        self.class.new(vtable.expand(@content))
      end

      # Return true if the content includes variables.
      #
      # @return [Boolean]
      #   true if the content includes variables
      def include_variable?
        return VariableTable.check_include_variable(@content)
      end

      # @api private
      def textize
        "action_block(\"#{@content}\")"
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @content == other.content
      end
      alias :eql? :"=="

      # @api private
      def hash
        @content.hash
      end
    end

    # FlowBlock represents flow element sequence.
    #
    # @example
    #   Flow
    #     rule Test1
    #     rule Test2
    #     rule Test3
    #   End
    #   #=> Block.new([ CallRule.new('Test1'),
    #                   CallRule.new('Test2'),
    #                   CallRule.new('Test3') ])
    class FlowBlock < BasicModel
      attr_reader :elements

      # Create a flow block.
      #
      # @param elements [Array<BasicModel>]
      #   flow elements
      def initialize(*elements)
        unless elements.all? {|elt| elt.kind_of?(BasicModel)}
          raise ArgumentError.new(elements)
        end
        @elements = elements
      end

      # Evaluate each elements and return it.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        assignments = @elements.select{|elt| elt.kind_of?(Assignment)}
        conditional_blocks = @elements.select{|elt| elt.kind_of?(ConditionalBlock)}
        call_rules = @elements.select{|elt| elt.kind_of?(CallRule)}

        if not(assignments.empty?)
          assignments.each do |assignment|
            assignment.eval(vtable)
          end
          FlowBlock.new(*(conditional_blocks+call_rules)).eval(vtable)
        elsif not(conditional_blocks.empty?)
          exception = nil
          new_blocks = []
          next_blocks = []
          conditional_blocks.each do |block|
            begin
              new_blocks << block.eval(vtable)
            rescue UnboundVariableError => e
              exception = e
              next_blocks << block
            end
          end
          # fail to evaluate conditional blocks
          if conditional_blocks == next_blocks
            raise exception
          end
          # next
          elements = new_blocks.inject([]){|elts, block| elts += block.elements}
          FlowBlock.new(*(elements + next_blocks + call_rules)).eval(vtable)
        else
          FlowBlock.new(*call_rules.map{|call_rule| call_rule.eval(vtable)})
        end
      end

      # Return true if the elements include variables.
      #
      # @return [Boolean]
      #   true if the elements include variables
      def include_variable?
        @elements.any?{|elt| elt.include_variable?}
      end

      # @api private
      def textize
        "flow_block(%s)" % [@elements.map{|elt| elt.textize}.join(",")]
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @elements == other.elements
      end
      alias :eql? :"=="

      # @api private
      def hash
        @elements.hash
      end
    end

    # ConditionalBlock represents conditional flow applications.
    #
    # @example
    #   # if statement
    #   if $X == "a"
    #     rule Test1
    #   else
    #     rule Test2
    #   end
    #   #=> ConditionalBlock.new(
    #         BinaryOperator::Equals.new(Variable.new('X'), 'a'),
    #         { true => [CallRule.new('Test1')],
    #           :else => [CallRule.new('Test2')] })
    # @example
    #   # case statement
    #   case $X
    #   when "a"
    #     rule Test1
    #   when "b"
    #     rule Test2
    #   else
    #     rule Test3
    #   end
    #   # => ConditionalBlock.new(
    #          Variable.new('X'),
    #          { 'a' => FlowBlock.new(CallRule.new('Test1')),
    #            'b' => FlowBlock.new(CallRule.new('Test2')),
    #            :else => FlowBlock.new(CallRule.new('Test3')) })
    class ConditionalBlock < BasicModel
      attr_reader :condition
      attr_reader :blocks

      # Create a conditional block.
      #
      # @param condition [BasicModel]
      #   condition value
      # @param blocks [Hash{BasicModel => FlowBlock}]
      #   condition key and block
      def initialize(condition, blocks={})
        unless blocks.all?{|key,val|
            (key.kind_of?(BasicModel) or key == :else) &&
            val.kind_of?(FlowBlock)
          }
          raise ArgumentError.new(blocks)
        end
        @condition = condition
        @blocks = blocks
      end

      # Evaluate the condition and returns the flow block.
      #
      # @param vtable [VariableTable]
      #   variable table for evaluation
      # @return [BasicModel]
      #   evaluation result
      def eval(vtable)
        value = @condition.eval(vtable)
        if block = @blocks.find {|key, _| key == value}
          return block[1].eval(vtable)
        elsif block = @blocks[:else]
          return block.eval(vtable)
        else
          return FlowBlock.new
        end
      end

      # Return ture if blocks include variables.
      #
      # @return [Boolean]
      #   ture if blocks include variables
      def include_variable?
        @blocks.values.any?{|block| block.include_variable?}
      end

      # @api private
      def textize
        "conditional_block(%s,{%s})" % [
          @condition.textize,
          @blocks.map{|val, block| "%s=>%s" % [val,block]}.join(",")
        ]
      end

      # @api private
      def ==(other)
        return false unless other.kind_of?(self.class)
        @condition == other.condition && @blocks == other.blocks
      end
      alias :eql? :"=="

      # @api private
      def hash
        @condition.hash + @blocks.hash
      end
    end
  end
end
