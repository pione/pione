require_relative '../test-util'

describe 'Pione::Transformer::RuleDefinitionTransformer' do
  transformer_spec("input_line", :input_line) do
    tc("input '*.txt'") do
      Naming.InputLine(DataExpr.new("*.txt"))
    end
  end

  transformer_spec("output_line", :output_line) do
    tc("output '*.txt'") do
      Naming.OutputLine(DataExpr.new("*.txt"))
    end
  end

  transformer_spec("param_line", :param_line) do
    tc("param {var: 1}") do
      Naming.ParamLine({"var" => 1}.to_params)
    end
    tc("param {var1: 1, var2: 2}") do
      Naming.ParamLine({"var1" => 1, "var2" => 2}.to_params)
    end
  end

  transformer_spec("feature_line", :feature_line) do
    tc("feature +A") do
      Naming.FeatureLine(Feature::RequisiteExpr.new("A"))
    end
  end

  transformer_spec("rule_definition", :rule_definition) do
    tc(<<-STRING) do
      Rule Test
        input  '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Action
        echo "test" > {$OUTPUT[1].NAME}
      End
    STRING
      ActionRule.new(
        RuleExpr.new(Package.new("main"), "Test"),
        RuleCondition.new(
          [ DataExpr.new('*.a') ],
          [ DataExpr.new('{$INPUT[1].MATCH[1]}.b') ],
          Parameters.empty,
          Feature.empty
        ),
        ActionBlock.new("        echo \"test\" > {$OUTPUT[1].NAME}\n")
      )
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
      FlowRule.new(
        RuleExpr.new(Package.new("main"), "Test"),
        RuleCondition.new(
          [ DataExpr.new('*.a') ],
          [ DataExpr.new('{$INPUT[1].MATCH[1]}.b') ],
          Parameters.empty,
          Feature.empty
        ),
        FlowBlock.new(
          CallRule.new(RuleExpr.new(Package.new("main"), "TestA")),
          CallRule.new(RuleExpr.new(Package.new("main"), "TestB"))
        )
      )
    end

    tc(<<-STRING) do
      Rule Main
        input '*.txt'.except('summary.txt')
        output 'summary.txt'
        param {ConvertCharSet: true}
      Flow
      if $ConvertCharset
        rule NKF.params("-w")
      end
      rule CountChar
      rule Summarize
      End
    STRING
      FlowRule.new(
        RuleExpr.new(Package.new("main"), "Main"),
        RuleCondition.new(
          [Message.new(
              "except",
              DataExpr.new("*.txt"),
              DataExpr.new("summary.txt"))],
          [DataExpr.new("summary.txt")],
          Parameters.new({Variable.new("ConvertCharSet") => PioneBoolean.true}),
          Feature.empty
        ),
        FlowBlock.new(
          ConditionalBlock.new(
            Variable.new("ConvertCharset"),
            { PioneBoolean.true => FlowBlock.new(
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
      )
    end
  end

  transformer_spec("rule_definitions", :toplevel_elements) do
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
            Parameters.empty,
            Feature.empty
          ),
          ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}\n")
        ),
        ActionRule.new(
          RuleExpr.new(Package.new("main"), "TestB"),
          RuleCondition.new(
            [ DataExpr.new("*.b") ],
            [ DataExpr.new('{$INPUT[1].MATCH[1]}.c') ],
            Parameters.empty,
            Feature.empty
          ),
          ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}\n")
        )
      ]
    end
  end
end

