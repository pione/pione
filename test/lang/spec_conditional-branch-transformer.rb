require 'pione/test-helper'

describe 'Pione::Transformer::ConditionalBranchTransformer' do
  transformer_spec("if_branch", :if_branch) do
    # simple branch
    test(<<-STRING) do |branch|
      if $x == 1
        $y := 1
      else
        $y := 2
      end
    STRING
      branch.should.kind_of Lang::IfBranch
      branch.pos.should.not.nil
      branch.expr.should == TestHelper::Lang.expr("$x == 1")
      branch.true_context.should.kind_of Lang::ConditionalBranchContext
      branch.true_context.elements.size.should == 1
      branch.true_context.elements[0].should == TestHelper::Lang.declaration("$y := 1")
      branch.else_context.should.kind_of Lang::ConditionalBranchContext
      branch.else_context.elements.size.should == 1
      branch.else_context.elements[0].should == TestHelper::Lang.declaration("$y := 2")
    end

    # without else-context
    test(<<-STRING) do |branch|
      if $x == 1
        $y := 1
      end
    STRING
      branch.should.kind_of Lang::IfBranch
      branch.pos.should.not.nil
      branch.expr.should == TestHelper::Lang.expr("$x == 1")
      branch.true_context.should.kind_of Lang::ConditionalBranchContext
      branch.true_context.elements.size.should == 1
      branch.true_context.elements[0].should == TestHelper::Lang.declaration("$y := 1")
      branch.else_context.should.kind_of Lang::ConditionalBranchContext
      branch.else_context.elements.size.should == 0
    end
  end

  transformer_spec("case_branch", :case_branch) do
    # simple case branch
    test(<<-STRING) do |branch|
      case $x
      when 1
        $y := 1
      when 2
        $y := 2
      else
        $y := 3
      end
    STRING
      branch.should.kind_of Lang::CaseBranch
      branch.pos.should.not.nil
      branch.expr.should == TestHelper::Lang.expr("$x")
      branch.when_contexts.should.kind_of Array
      branch.when_contexts.size.should == 2
      branch.when_contexts[0][0].should == TestHelper::Lang.expr("1")
      branch.when_contexts[0][1].should.kind_of Lang::ConditionalBranchContext
      branch.when_contexts[0][1].elements.size.should == 1
      branch.when_contexts[0][1].elements[0].should == TestHelper::Lang.declaration("$y := 1")
      branch.when_contexts[1][0].should == TestHelper::Lang.expr("2")
      branch.when_contexts[0][1].should.kind_of Lang::ConditionalBranchContext
      branch.when_contexts[1][1].elements.size.should == 1
      branch.when_contexts[1][1].elements[0].should == TestHelper::Lang.declaration("$y := 2")
      branch.else_context.should.kind_of Lang::ConditionalBranchContext
      branch.else_context.elements.size.should == 1
      branch.else_context.elements[0].should == TestHelper::Lang.declaration("$y := 3")
    end

    # without else context
    test(<<-STRING) do |branch|
      case $x
      when 1
        $y := 1
      when 2
        $y := 2
      end
    STRING
      branch.should.kind_of Lang::CaseBranch
      branch.pos.should.not.nil
      branch.expr.should == TestHelper::Lang.expr("$x")
      branch.when_contexts.should.kind_of Array
      branch.when_contexts.size.should == 2
      branch.when_contexts[0][0].should == TestHelper::Lang.expr("1")
      branch.when_contexts[0][1].should.kind_of Lang::ConditionalBranchContext
      branch.when_contexts[0][1].elements.size.should == 1
      branch.when_contexts[0][1].elements[0].should == TestHelper::Lang.declaration("$y := 1")
      branch.when_contexts[1][0].should == TestHelper::Lang.expr("2")
      branch.when_contexts[0][1].should.kind_of Lang::ConditionalBranchContext
      branch.when_contexts[1][1].elements.size.should == 1
      branch.when_contexts[1][1].elements[0].should == TestHelper::Lang.declaration("$y := 2")
      branch.else_context.should.kind_of Lang::ConditionalBranchContext
      branch.else_context.elements.size.should == 0
    end
  end
end
