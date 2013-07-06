require_relative '../test-util'

describe 'Pione::Transformer::FlowElementTransformer' do
  transformer_spec("call_rule_line", :call_rule_line) do
    test "rule Test" do |elt|
      elt.should.kind_of CallRule
      elt.expr.should == RuleExpr.new(PackageExpr.new("Main"), "Test")
    end

    test "rule :Test" do |elt|
      elt.should.kind_of CallRule
      elt.expr.should == RuleExpr.new(PackageExpr.new("Main"), "Test")
    end

    test "rule &test:Test" do |elt|
      elt.should.kind_of CallRule
      elt.expr.should == RuleExpr.new(PackageExpr.new("test"), "Test")
    end

    test "rule $var" do |elt|
      elt.should.kind_of CallRule
      elt.expr.should == Variable.new("var")
    end
  end

  transformer_spec("assignment", :assignment) do
    test "$var := 1" do |elt|
      elt.should.kind_of Assignment
      elt.variable.should == Variable.new("var")
      elt.expr.should == IntegerSequence.new([PioneInteger.new(1)])
    end

    test "$a := $b" do |elt|
      elt.should.kind_of Assignment
      elt.variable.should == Variable.new("a")
      elt.expr.should == Variable.new("b")
    end

    test "$var := &package:test" do |elt|
      elt.should.kind_of Assignment
      elt.variable.should == Variable.new("var")
      elt.expr.should == RuleExpr.new(PackageExpr.new("package"), "test")
    end
  end

  transformer_spec("if_block", :if_block) do
    test(<<-STRING) do |elt|
      if $Var == 1
        rule A
      end
    STRING
      elt.should.kind_of ConditionalBlock
      elt.condition.should.kind_of Message
      elt.condition.name.should == "=="
      elt.condition.receiver.should == Variable.new("Var")
      elt.condition.arguments.should == [IntegerSequence.new([PioneInteger.new(1)])]
      elt.blocks[BooleanSequence.new([PioneBoolean.true])].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "A")))
    end

    test(<<-STRING) do |elt|
      if $Var == "a"
        rule A
      else
        rule B
      end
    STRING
      elt.should.kind_of ConditionalBlock
      elt.condition.should.kind_of Message
      elt.condition.name.should == "=="
      elt.condition.receiver.should == Variable.new("Var")
      elt.condition.arguments.should == [StringSequence.new([PioneString.new("a")])]
      elt.blocks[BooleanSequence.new([PioneBoolean.true])].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "A")))
      elt.blocks[:else].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "B")))
    end

    test(<<-STRING) do |elt|
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
      pione_true = BooleanSequence.new([PioneBoolean.true])

      elt.should.kind_of Model::ConditionalBlock
      elt.condition.should == Variable.new("a")
      elt.blocks[pione_true].tap do |inner|
        inner.should.kind_of Model::FlowBlock
        inner.elements[0].tap do |_elt|
          _elt.condition.should == Variable.new("b")
          _elt.blocks[pione_true].should ==
            Model::FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "Test1")))
          _elt.blocks[:else].should ==
            Model::FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "Test2")))
        end
      end
      elt.blocks[:else].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "Test3")))
    end
  end

  transformer_spec("case_block", :case_block) do
    test(<<-STRING) do |elt|
      case $Var
      when "a"
        rule A
      when "b"
        rule B
      when "c"
        rule C
      end
    STRING
      elt.should.kind_of ConditionalBlock
      elt.condition.should == Variable.new("Var")
      elt.blocks[StringSequence.new([PioneString.new("a")])].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "A")))
      elt.blocks[StringSequence.new([PioneString.new("b")])].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "B")))
      elt.blocks[StringSequence.new([PioneString.new("c")])].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "C")))
    end

    test(<<-STRING) do |elt|
      case $Var
      when "a"
        rule Test1
      else
        rule Test2
      end
    STRING
      elt.should.kind_of ConditionalBlock
      elt.condition.should == Variable.new("Var")
      elt.blocks[StringSequence.new([PioneString.new("a")])].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "Test1")))
      elt.blocks[:else].should ==
        FlowBlock.new(CallRule.new(RuleExpr.new(PackageExpr.new("Main"), "Test2")))
    end
  end
end
