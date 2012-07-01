require_relative '../test-util'

describe 'Transformer::FlowElement' do
  transformer_spec("call_rule_line", :call_rule_line) do
    tc("rule Test" => CallRule.new(RuleExpr.new("Test")))
  end

  transformer_spec("if_block", :if_block) do
    tc(<<-STRING) do
      if $Var == 1
        rule A
      end
    STRING
      ConditionalBlock.new(BinaryOperator.new("==",
                                              Variable.new("Var"),
                                              PioneInteger.new(1)),
                           { true =>
                             Block.new(CallRule.new(RuleExpr.new("A")))
                           })
    end
    tc(<<-STRING) do
      if $Var == "a"
        rule A
      else
        rule B
      end
    STRING
      ConditionalBlock.new(BinaryOperator.new("==",
                                              Variable.new("Var"),
                                              PioneString.new("a")),
                           { true =>
                             Block.new(CallRule.new(RuleExpr.new("A"))),
                             :else =>
                             Block.new(CallRule.new(RuleExpr.new("B")))
                           })
    end
    tc(<<-STRING) do
      if $a
        if $b
          rule Test1
        else
          rule Test2
        end
      else
        rule Test3
      end
    STRING
      inner_block =
        Block.new(ConditionalBlock.new(Variable.new("b"),
                                       { true =>
                                         Block.new(CallRule.new("Test1")),
                                         :else =>
                                         Block.new(CallRule.new("Test2"))
                                       }))
      ConditionalBlock.new(Variable.new("a"),
                           { true => inner_block,
                             :else => Block.new(CallRule.new("Test3"))
                           })
    end
  end

  transformer_spec("case_block", :case_block) do
    tc(<<-STRING) do
      case $Var
      when "a"
        rule A
      when "b"
        rule B
      when "c"
        rule C
      end
    STRING
      ConditionalBlock.new(Variable.new("Var"),
                           { PioneString.new("a") =>
                             Block.new(CallRule.new(RuleExpr.new("A"))),
                             PioneString.new("b") =>
                             Block.new(CallRule.new(RuleExpr.new("B"))),
                             PioneString.new("c") =>
                             Block.new(CallRule.new(RuleExpr.new("C"))) })
    end
    tc(<<-STRING) do
      case $Var
      when "a"
        rule Test1
      else
        rule Test2
      end
    STRING
      ConditionalBlock.new(Variable.new("Var"),
                           { PioneString.new("a") =>
                             Block.new(CallRule.new(RuleExpr.new("Test1"))),
                             :else =>
                             Block.new(CallRule.new(RuleExpr.new("Test2")))
                           })
    end
  end
end
