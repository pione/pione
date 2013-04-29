require_relative '../test-util'

describe 'Pione::Transformer::BlockTransformer' do
  transformer_spec("action_block", :action_block) do
    tc(<<-STRING) do
      Action
        echo "a"
      End
    STRING
      ActionBlock.new("        echo \"a\"\n")
    end
  end

  transformer_spec("flow_block", :flow_block) do
    tc(<<-STRING) do
      Flow
        rule Test
      End
    STRING
      FlowBlock.new(
        CallRule.new(RuleExpr.new(Package.new("main"), "Test"))
      )
    end
  end

  transformer_spec("empty_block", :empty_block) do
    tc(<<-STRING) do
      End
    STRING
      EmptyBlock.instance
    end
  end
end
