require 'pione/test-helper'

describe 'Pione::Transformer::DeclarationTransformer' do
  transformer_spec("variable_binding_sentence", :variable_binding_sentence) do
    test "$X := true" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::VariableBindingDeclaration
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should == Lang::BooleanSequence.of(true)
    end

    test "bind $X := true" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::VariableBindingDeclaration
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should == Lang::BooleanSequence.of(true)
    end
  end

  transformer_spec("package_binding_sentence", :package_binding_sentence) do
    test "package $P <- &Package" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::PackageBindingDeclaration
      declaration.expr1.should == Lang::Variable.new("P")
      declaration.expr2.should == Lang::PackageExprSequence.of("Package")
    end
  end

  transformer_spec("param_sentence", :param_sentence) do
    # default type without default value
    test "param $X" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamDeclaration
      declaration.type.should == :basic
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should.nil
    end

    # default type with default value
    test "param $X := 1" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamDeclaration
      declaration.type.should == :basic
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should == Lang::IntegerSequence.of(1)
    end

    # basic type without default value
    test "basic param $X" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamDeclaration
      declaration.type.should == :basic
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should.nil
    end

    # basic type with default value
    test "basic param $X := 1" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamDeclaration
      declaration.type.should == :basic
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should == Lang::IntegerSequence.of(1)
    end

    # advanced type without default value
    test "advanced param $X" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamDeclaration
      declaration.type.should == :advanced
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should.nil
    end

    # advanced type with default value
    test "advanced param $X := 1" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamDeclaration
      declaration.type.should == :advanced
      declaration.expr1.should == Lang::Variable.new("X")
      declaration.expr2.should == Lang::IntegerSequence.of(1)
    end
  end

  transformer_spec("rule_binding_declaration", :rule_binding_sentence) do
    test "rule A := B" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::RuleBindingDeclaration
      declaration.expr1.should == Lang::RuleExprSequence.of("A")
      declaration.expr2.should == Lang::RuleExprSequence.of("B")
    end
  end

  transformer_spec("input_sentence", :input_sentence) do
    test "input '*.txt'" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::InputDeclaration
      declaration.expr.should == Lang::DataExprSequence.of("*.txt")
    end
  end

  transformer_spec("output_sentence", :output_sentence) do
    test("output '*.txt'") do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::OutputDeclaration
      declaration.expr.should == Lang::DataExprSequence.of("*.txt")
    end
  end

  transformer_spec("feature_sentence", :feature_sentence) do
    test "feature +A" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::FeatureDeclaration
      declaration.expr.should == Lang::FeatureSequence.of(Lang::RequisiteFeature.new("A"))
    end
  end

  transformer_spec("constituent_rule_sentence", :constituent_rule_sentence) do
    test "rule A" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ConstituentRuleDeclaration
      declaration.expr.should == Lang::RuleExprSequence.of("A")
    end
  end

  transformer_spec("annotation_sentence", :annotation_sentence) do
    test ".@ author :: \"Keita Yamaguchi\"" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::AnnotationDeclaration
      declaration.expr.should == TestHelper::Lang.expr("author :: \"Keita Yamaguchi\"")
    end
  end

  transformer_spec("expr_sentence", :expr_sentence) do
    test "? 1 + 1" do |declaration|
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ExprDeclaration
      declaration.expr.should == TestHelper::Lang.expr("1 + 1")
    end
  end

  transformer_spec("param_block", :param_block) do
    # implicit basic type
    test(<<-STRING) do |declaration|
      Param
        $X := 1
        $Y := 2
        $Z := 3
      End
    STRING
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamBlockDeclaration
      declaration.type.should == :basic
      declaration.context.should.kind_of Lang::ParamContext
      declaration.context.elements.size == 3
      declaration.context.elements[0].should.kind_of Lang::VariableBindingDeclaration
      declaration.context.elements[1].should.kind_of Lang::VariableBindingDeclaration
      declaration.context.elements[2].should.kind_of Lang::VariableBindingDeclaration
    end

    # explicit basic type
    test(<<-STRING) do |declaration|
      Basic Param
        $X := 1
        $Y := 2
        $Z := 3
      End
    STRING
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamBlockDeclaration
      declaration.type.should == :basic
      declaration.context.should.kind_of Lang::ParamContext
      declaration.context.elements.size == 3
      declaration.context.elements[0].should.kind_of Lang::VariableBindingDeclaration
      declaration.context.elements[1].should.kind_of Lang::VariableBindingDeclaration
      declaration.context.elements[2].should.kind_of Lang::VariableBindingDeclaration
    end

    # advanced type
    test(<<-STRING) do |declaration|
      Advanced Param
        $X := 1
        $Y := 2
        $Z := 3
      End
    STRING
      declaration.pos.line.should == 1
      declaration.pos.column.should == 1
      declaration.should.kind_of Lang::ParamBlockDeclaration
      declaration.type.should == :advanced
      declaration.context.should.kind_of Lang::ParamContext
      declaration.context.elements.size == 3
      declaration.context.elements[0].should.kind_of Lang::VariableBindingDeclaration
      declaration.context.elements[1].should.kind_of Lang::VariableBindingDeclaration
      declaration.context.elements[2].should.kind_of Lang::VariableBindingDeclaration
    end
  end

  transformer_spec("flow_rule_block", :flow_rule_block) do
    test(<<-STRING) do |declaration|
      Rule R
        input '*.a'
        output '{$*}.b'
      Flow
        rule A
      End
    STRING
      declaration.should.kind_of Lang::FlowRuleDeclaration
      declaration.expr.should == Lang::RuleExprSequence.of("R")
      declaration.rule_condition_context.should.kind_of Lang::RuleConditionContext
      declaration.rule_condition_context.elements.size.should == 2
      declaration.rule_condition_context.elements[0] == TestHelper::Lang.declaration("input '*.a'")
      declaration.rule_condition_context.elements[1] == TestHelper::Lang.declaration("output '{$*}.b'")
      declaration.flow_context.should.kind_of Lang::FlowContext
      declaration.flow_context.elements.size.should == 1
      declaration.flow_context.elements[0].should == TestHelper::Lang.declaration("rule A")
    end
  end

  transformer_spec("action_rule_block", :action_rule_block) do
    test(<<-STRING) do |declaration|
      Rule R
        input '*.a'
        output '{$*}.b'
      Action
        cat {$I[0]} > {$O[0]}
      End
    STRING
      declaration.should.kind_of Lang::ActionRuleDeclaration
      declaration.expr.should == Lang::RuleExprSequence.of("R")
      declaration.condition_context.should.kind_of Lang::RuleConditionContext
      declaration.condition_context.elements.size.should == 2
      declaration.condition_context.elements[0] == TestHelper::Lang.declaration("input '*.a'")
      declaration.condition_context.elements[1] == TestHelper::Lang.declaration("output '{$*}.b'")
      declaration.action_context.should == Lang::ActionContext.new("cat {$I[0]} > {$O[0]}\n")
    end
  end

  transformer_spec("empty_rule_block", :empty_rule_block) do
    test(<<-STRING) do |declaration|
      Rule R
        input '*.a'
        output '{$*}.b'.touch
      End
    STRING
      declaration.should.kind_of Lang::EmptyRuleDeclaration
      declaration.expr.should == Lang::RuleExprSequence.of("R")
      declaration.condition_context.should.kind_of Lang::RuleConditionContext
      declaration.condition_context.elements.size.should == 2
      declaration.condition_context.elements[0] == TestHelper::Lang.declaration("input '*.a'")
      declaration.condition_context.elements[1] == TestHelper::Lang.declaration("output '{$*}.b'.touch")
    end
  end
end
