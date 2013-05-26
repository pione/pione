require_relative '../test-util'

describe 'Pione::Transformer::RuleDefinitionTransformer' do
  transformer_spec("input_line", :input_line) do
    tc("input '*.txt'") do
      Naming.InputLine(DataExpr.new("*.txt").to_seq)
    end
  end

  transformer_spec("output_line", :output_line) do
    tc("output '*.txt'") do
      Naming.OutputLine(DataExpr.new("*.txt").to_seq)
    end
  end

  transformer_spec("param_line", :param_line) do
    tc("param {var: 1}") do
      Naming.ParamLine(
        Parameters.new(
          {Variable.new("var") => IntegerSequence.new([PioneInteger.new(1)])}
        )
      )
    end
    tc("param {var1: 1, var2: 2}") do
      Naming.ParamLine(
        Parameters.new(
          { Variable.new("var1") => IntegerSequence.new([PioneInteger.new(1)]),
            Variable.new("var2") => IntegerSequence.new([PioneInteger.new(2)]) }
        )
      )
    end
  end

  transformer_spec("feature_line", :feature_line) do
    tc("feature +A") do
      Naming.FeatureLine(Feature::RequisiteExpr.new("A"))
    end
  end

  transformer_spec("rule_definition", :rule_definition) do
    transform(<<-STRING) do |rule|
      Rule Test
        input  '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Action
        echo "test" > {$OUTPUT[1].NAME}
      End
    STRING
      rule.should.kind_of(Component::ActionRule)
      rule.condition.inputs[0].should == DataExpr.new('*.a').to_seq
      rule.condition.outputs[0].should == DataExpr.new('{$INPUT[1].MATCH[1]}.b').to_seq
      rule.body.should ==
        ActionBlock.new("        echo \"test\" > {$OUTPUT[1].NAME}\n")
    end

    transform(<<-STRING) do |rule|
      Rule Test
        input '*.a'
        output '{$INPUT[1].MATCH[1]}.b'
      Flow
        rule TestA
        rule TestB
      End
    STRING
      rule.should.kind_of(Component::FlowRule)
      rule.condition.inputs[0].should == DataExpr.new('*.a').to_seq
      rule.condition.outputs[0].should == DataExpr.new('{$INPUT[1].MATCH[1]}.b').to_seq
      rule.body.should == FlowBlock.new(
        CallRule.new(RuleExpr.new(PackageExpr.new("main"), "TestA")),
        CallRule.new(RuleExpr.new(PackageExpr.new("main"), "TestB"))
      )
    end

    transform(<<-STRING) do |rule|
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
      rule.should.kind_of(Component::FlowRule)
      rule.condition.inputs[0].should == Message.new(
        "except",
        DataExpr.new("*.txt").to_seq,
        DataExpr.new("summary.txt").to_seq
      )
      rule.condition.outputs[0].should == DataExpr.new("summary.txt").to_seq
      rule.condition.params.should == Parameters.new(
        Variable.new("ConvertCharSet") =>
        BooleanSequence.new([PioneBoolean.true])
      )
      rule.body.should == FlowBlock.new(
        ConditionalBlock.new(
          Variable.new("ConvertCharset"),
          { BooleanSequence.new([PioneBoolean.true]) =>
            FlowBlock.new(
              CallRule.new(Message.new(
                  "params",
                  RuleExpr.new(PackageExpr.new("main"), "NKF"),
                  StringSequence.new([PioneString.new("-w")])
              ))
            )}
        ),
        CallRule.new(
          RuleExpr.new(PackageExpr.new("main"), "CountChar")
        ),
        CallRule.new(
          RuleExpr.new(PackageExpr.new("main"), "Summarize")
        )
      )
    end

    transform(<<-STRING) do |rule|
      Rule EmptyRule
        input '*.a'
        output '*.a'.touch
      End
    STRING
      rule.should.kind_of(Component::EmptyRule)
      rule.condition.inputs[0].should == DataExpr.new("*.a").to_seq
      rule.condition.outputs[0].should == Message.new("touch", DataExpr.new("*.a").to_seq)
    end
  end

  transformer_spec("rule_definitions", :toplevel_elements) do
    transform(<<-STRING) do |rules|
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
      rules[0].should.kind_of(Component::ActionRule)
      rules[0].condition.inputs[0].should == DataExpr.new("*.a").to_seq
      rules[0].condition.outputs[0].should == DataExpr.new('{$INPUT[1].MATCH[1]}.b').to_seq
      rules[0].body.should ==
        ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}\n")
      rules[1].should.kind_of(Component::ActionRule)
      rules[1].condition.inputs[0].should == DataExpr.new("*.b").to_seq
      rules[1].condition.outputs[0].should == DataExpr.new('{$INPUT[1].MATCH[1]}.c').to_seq
      rules[1].body.should ==
        ActionBlock.new("      cat {$INPUT[1].NAME} > {$OUTPUT[1].NAME}\n")
    end
  end
end

