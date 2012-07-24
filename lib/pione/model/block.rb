module Pione::Model
  # ActionBlock represents content script of action.
  #   Action
  #   echo "abc"
  #   End
  #   => ActionBlock.new("  echo \"abc\"")
  class ActionBlock < PioneModelObject
    attr_reader :content

    def initialize(content)
      @content = content
    end

    # Expands variables.
    def eval(vtable)
      self.class.new(vtable.expand(@content))
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @content == other.content
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @content.hash
    end
  end

  # FlowBlock represents flow element sequence.
  #   Flow
  #     rule Test1
  #     rule Test2
  #     rule Test3
  #   End
  #   => Block.new([ CallRule.new('Test1'),
  #                  CallRule.new('Test2'),
  #                  CallRule.new('Test3') ])
  class FlowBlock < PioneModelObject
    attr_reader :elements

    def initialize(*elements)
      unless elements.all? {|elt| elt.kind_of?(PioneModelObject)}
        raise ArgumentError.new(elements)
      end
      @elements = elements
    end

    # Evaluates each elements and return it.
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
        FlowBlock.new(*call_rules)
      end
    end

    def ==(other)
      return false unless other.kind_of?(self.class)
      @elements == other.elements
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @elements.hash
    end
  end

  # ConditionalBlock represents conditional flow applications.
  # For example of /if/ statement:
  #   if $X == "a"
  #     rule Test1
  #   else
  #     rule Test2
  #   end
  #   => ConditionalBlock.new(
  #        BinaryOperator::Equals.new(Variable.new('X'), 'a'),
  #                           { true => [CallRule.new('Test1')],
  #                             :else => [CallRule.new('Test2')] })
  #
  # For example of case statement:
  #   case $X
  #   when "a"
  #     rule Test1
  #   when "b"
  #     rule Test2
  #   else
  #     rule Test3
  #   end
  #   => ConditionalBlock.new(
  #        Variable.new('X'),
  #        { 'a' => FlowBlock.new(CallRule.new('Test1')),
  #          'b' => FlowBlock.new(CallRule.new('Test2')),
  #          :else => FlowBlock.new(CallRule.new('Test3')) })
  #
  class ConditionalBlock < PioneModelObject
    attr_reader :condition
    attr_reader :blocks

    def initialize(condition, blocks={})
      unless blocks.all?{|key,val|
          (key.kind_of?(PioneModelObject) or key == :else) &&
          val.kind_of?(FlowBlock)
        }
        raise ArgumentError.new(blocks)
      end
      @condition = condition
      @blocks = blocks
    end

    # Evaluates the condition and returns the flow block.
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

    def ==(other)
      return false unless other.kind_of?(self.class)
      @condition == other.condition && @blocks == other.blocks
    end

    alias :eql? :==

    # Returns hash value.
    def hash
      @condition.hash + @blocks.hash
    end
  end
end
