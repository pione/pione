require_relative '../test-util'

ConditionLine = Transformer::RuleDefinition::ConditionLine

describe 'Transformer::RuleDefinition' do
  transformer_spec("input_line", :input_line) do
    tc("input '*.txt'") do
      ConditionLine.new(:input, DataExpr.new("*.txt"))
    end
  end

  transformer_spec("output_line", :output_line) do
    tc("output '*.txt'") do
      ConditionLine.new(:output, DataExpr.new("*.txt"))
    end
  end

  transformer_spec("param_line", :param_line) do
    tc("param $var") do
      ConditionLine.new(:param, Variable.new("var"))
    end
  end

  transformer_spec("param_line", :param_line) do
    tc("param $var") do
      ConditionLine.new(:param, Variable.new("var"))
    end
  end

  transformer_spec("rule_definition", :rule_definitions) do
    tc(<<STRING) do
Rule Test
  input  '*.a'
output '{$INPUT[1].MATCH[1]}.b'
Action
echo "test" > {$OUTPUT[1].NAME}
End
STRING
      [ActionRule.new(
        RuleExpr.new(Package.new("main"), "Test"),
        RuleCondition.new(
          [ DataExpr.new('*.a') ],
          [ DataExpr.new('{$INPUT[1].MATCH[1]}.b') ],
          [],
          []
        ),
          ActionBlock.new("echo \"test\" > {$OUTPUT[1].NAME}\n")
      )]
    end

    tc(<<-STRING) do
      Rule Test
        input '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Flow
      rule TestA
      rule TestB
      End
    STRING
      [ FlowRule.new(
          RuleExpr.new(Package.new("main"), "Test"),
          RuleCondition.new(
            [ DataExpr.new('*.a') ],
            [ DataExpr.new('{$INPUT[1].MATCH[1]}.b') ],
            [],
            []
          ),
          FlowBlock.new(
            CallRule.new(RuleExpr.new(Package.new("main"), "TestA")),
            CallRule.new(RuleExpr.new(Package.new("main"), "TestB"))
          )
      )]
    end

    tc(<<-STRING) do
      Rule Main
        input '*.txt'.except('summary.txt')
        output 'summary.txt'
        param $ConvertCharSet
      Flow
      if $ConvertCharset
        rule NKF.params("-w")
      end
      rule CountChar
      rule Summarize
      End
    STRING
      [ FlowRule.new(
          RuleExpr.new(Package.new("main"), "Main"),
          RuleCondition.new(
            [Message.new(
                "except",
                DataExpr.new("*.txt"),
                DataExpr.new("summary.txt"))],
            [DataExpr.new("summary.txt")],
            [Variable.new("ConvertCharSet")],
            []
          ),
          FlowBlock.new(
            ConditionalBlock.new(
              Variable.new("ConvertCharset"),
              { true => FlowBlock.new(
                  CallRule.new(Message.new(
                      "params",
                      RuleExpr.new(Package.new("main"), "NKF"),
                      PioneString.new("-w")
                  ))
              )}
            ),
            CallRule.new(
              RuleExpr.new(Package.new("main"), "CountChar")
            ),
            CallRule.new(
              RuleExpr.new(Package.new("main"), "Summarize")
            )
          )
      )]
    end
  end

  transformer_spec("rule_definitions", :rule_definitions) do
    tc(<<-STRING) do
      Rule TestA
        input  '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Action
      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}
      End

      Rule TestB
        input  '*.b'
        output '{$INPUT[1].MATCH[1]}.c'
      Action
      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}
      End
    STRING
      [
        ActionRule.new(
          RuleExpr.new(Package.new("main"), "TestA"),
          RuleCondition.new(
            [ DataExpr.new("*.a") ],
            [ DataExpr.new('{$INPUT[1].MATCH[1]}.b') ],
            [],
            []
          ),
          ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}\n")
        ),
        ActionRule.new(
          RuleExpr.new(Package.new("main"), "TestB"),
          RuleCondition.new(
            [ DataExpr.new("*.b") ],
            [ DataExpr.new('{$INPUT[1].MATCH[1]}.c') ],
            [],
            []
          ),
          ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}\n")
        )
      ]
    end
  end
end

