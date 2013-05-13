require_relative '../test-util'

describe 'Pione::Transformer::FlowElementTransformer' do
  transformer_spec("call_rule_line", :call_rule_line) do
    tc(
      "rule Test" =>
      CallRule.new(RuleExpr.new(Package.new("main"), "Test"))
    )
    tc(
      "rule :Test" =>
      CallRule.new(RuleExpr.new(Package.new("main"), "Test"))
    )
    tc(
      "rule &test:Test" =>
      CallRule.new(RuleExpr.new(Package.new("test"), "Test"))
    )
    tc("rule $var" => CallRule.new(Variable.new("var")))
  end

  transformer_spec("assignment", :assignment) do
    tc(
      "$var := 1" =>
      Assignment.new(Variable.new("var"), IntegerSequence.new([PioneInteger.new(1)]))
    )
    tc(
      "$a := $b" =>
      Assignment.new(Variable.new("a"), Variable.new("b"))
    )
    tc(
      "$var := &package:test" =>
      Assignment.new(
        Variable.new("var"),
        RuleExpr.new(Package.new("package"), "test")
      )
    )
  end

  transformer_spec("if_block", :if_block) do
    tc(<<-STRING) do
      if $Var == 1
        rule A
      end
    STRING
      ConditionalBlock.new(
        BinaryOperator.new(
          "==",
          Variable.new("Var"),
          IntegerSequence.new([PioneInteger.new(1)])
        ),
        { BooleanSequence.new([PioneBoolean.true]) =>
          FlowBlock.new(
            CallRule.new(RuleExpr.new(Package.new("main"), "A"))
          )
        }
      )
    end
    tc(<<-STRING) do
      if $Var == "a"
        rule A
      else
        rule B
      end
    STRING
      ConditionalBlock.new(
        BinaryOperator.new(
          "==",
          Variable.new("Var"),
          StringSequence.new([PioneString.new("a")])
        ),
        { BooleanSequence.new([PioneBoolean.true]) =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "A"))),
          :else =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "B")))
        }
      )
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
      inner_block = FlowBlock.new(
        ConditionalBlock.new(
          Variable.new("b"),
          { BooleanSequence.new([PioneBoolean.true]) =>
            FlowBlock.new(
              CallRule.new(RuleExpr.new(Package.new("main"), "Test1"))
            ),
            :else =>
            FlowBlock.new(
              CallRule.new(RuleExpr.new(Package.new("main"), "Test2"))
            )
          }
        )
      )
      ConditionalBlock.new(
        Variable.new("a"),
        { BooleanSequence.new([PioneBoolean.true]) => inner_block,
          :else =>
          FlowBlock.new(
            CallRule.new(RuleExpr.new(Package.new("main"), "Test3"))
          )
        }
      )
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
      ConditionalBlock.new(
        Variable.new("Var"),
        { StringSequence.new([PioneString.new("a")]) =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "A"))),
          StringSequence.new([PioneString.new("b")]) =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "B"))),
          StringSequence.new([PioneString.new("c")]) =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "C")))
        }
      )
    end
    tc(<<-STRING) do
      case $Var
      when "a"
        rule Test1
      else
        rule Test2
      end
    STRING
      ConditionalBlock.new(
        Variable.new("Var"),
        { StringSequence.new([PioneString.new("a")]) =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "Test1"))),
          :else =>
          FlowBlock.new(CallRule.new(RuleExpr.new(Package.new("main"), "Test2")))
        }
      )
    end
  end
end
