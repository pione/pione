require_relative '../test-util'

describe 'Transformer::RuleDefinition' do
  transformer_spec("rule_definition", :rule_definitions) do
    tc(<<-STRING) do
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
        "echo \"test\" > {$OUTPUT[1].NAME}"
      )]
    end

    tc(<<-STRING) do
      Rule Test
        input '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Flow
      rule TestA
      rule TestB.sync
      End
    STRING
      FlowRule.new(
        RuleExpr.new(Package.new("main"), "Test"),
        RuleCondition.new(
          [ DataExpr.new('*.a') ],
          [ DataExpr.new('{$INPUT[1].MATCH[1]}.b') ],
          [],
          []
        ),
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("main"), "TestA")),
          CallRule.new(RuleExpr.new(Package.new("main"), "TestB").sync(true))
        )
      )
    end

    tc(<<-STRING) do
      Rule Main
        input '*.txt'.all.except('summary.txt')
        output 'summary.txt'
        param $ConvertCharSet
      Flow---
      if $ConvertCharset
        rule NKF.params("-w")
      end
      rule CountChar.sync
      rule Summarize
      ---End
    STRING
      FlowRule.new(
        RuleExpr.new(Package.new("main"), "Main"),
        RuleCondition.new(
          [DataExpr.new("*.txt").all.except("summary.txt")],
          [DataExpr.new("summary.txt")],
          [Variable.new("ConvertCharSet")],
          []
        ),
        FlowBlock.new(
          ConditionalBlock.new(
            Variable.new("CounvertCharset"),
            { true => FlowBlock.new(
                CallRule.new(
                  RuleExpr.new(Package.new("main"), "NKF").set_params("-w")
                )
            )}
          ),
          CallRule.new(
            RuleExpr.new(Package.new("main"), "CountChar").sync(true)
          ),
          CallRule.new(
            RuleExpr.new(Package.new("main"), "Summarize")
          )
        )
      )
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
          ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}")
        ),
        ActionRule.new(
          RuleExpr.new(Package.new("main"), "TestB"),
          RuleCondition.new(
            [ DataExpr.new("*.b") ],
            [ DataExpr.new('{$INPUT[1].MATCH[1]}.c') ],
            [],
            []
          ),
          ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}")
        )
      ]
    end
  end
end

