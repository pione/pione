require_relative '../test-util'

describe 'Pione::Transformer::BlockTransformer' do
  transformer_spec("action_block", :action_block) do
    test(<<-STRING) do |block|
      Action
        echo "a"
      End
    STRING
      block.should.kind_of ActionBlock
      block.content.should == "        echo \"a\"\n"
    end
  end

  transformer_spec("flow_block", :flow_block) do
    test(<<-STRING) do |block|
      Flow
        rule Test
      End
    STRING
      block.should.kind_of FlowBlock
      block.elements.size.should == 1
      block.elements[0].should == CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "Test"))
    end
  end

  transformer_spec("empty_block", :empty_block) do
    test(<<-STRING) do |block|
      End
    STRING
      block.should == EmptyBlock.instance
    end
  end
end
