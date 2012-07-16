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
      @elements = elements
    end

    # Evaluates each elements and return it.
    def eval(vtable)
      @elements.map{|e| e.eval(vtable)}
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
  #        { 'a' => Block.new([CallRule.new('Test1')]),
  #          'b' => Block.new([CallRule.new('Test2')]),
  #          :else => Block.new([CallRule.new('Test3')]) })
  #
  class ConditionalBlock < PioneModelObject
    attr_reader :condition
    attr_reader :blocks

    def initialize(condition, blocks={})
      @condition = condition
      @blocks = blocks
    end

    # Evaluates the condition and returns the flow block.
    def eval(vtable=VariableTable.new)
      value = @condition.eval(vtable)
      block = @blocks.find {|key, _| key === value}
      block = block[1] unless block.nil?
      block = @blocks[:else] if block.nil?
      block = [] if block.nil?
      return block.eval(vtable)
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
