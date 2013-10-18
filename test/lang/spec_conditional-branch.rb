require 'pione/test-helper'

describe "Pione::Lang::IfBranch" do
  before do
    @branch = TestHelper::Lang.conditional_branch(<<-STRING)
      if $x == 1
        $y := 1
      else
        $y := 2
      end
    STRING

    @branch_without_else = TestHelper::Lang.conditional_branch(<<-STRING)
      if $x == 1
        $y := 1
      end
    STRING

    @fake_branch = TestHelper::Lang.conditional_branch(<<-STRING)
      if true
        $y := 1
      else
        $y := 2
      end
    STRING

    @invalid_branch = TestHelper::Lang.conditional_branch(<<-STRING)
      if 1
        $y := 1
      else
        $y := 2
      end
    STRING
  end

  it "should get expr" do
    @branch.expr.should == TestHelper::Lang.expr("$x == 1")
  end

  it "shold get true-context" do
    @branch.true_context.should.kind_of Lang::ConditionalBranchContext
    @branch.true_context.elements.size.should == 1
    @branch.true_context.elements[0].should == TestHelper::Lang.declaration("$y := 1")
  end

  it "shold get else-context" do
    @branch.else_context.should.kind_of Lang::ConditionalBranchContext
    @branch.else_context.elements.size.should == 1
    @branch.else_context.elements[0].should == TestHelper::Lang.declaration("$y := 2")

    # if branch has no else context, we expect to get an empty context
    @branch_without_else.else_context.should.kind_of Lang::ConditionalBranchContext
    @branch_without_else.else_context.elements.size.should == 0
  end

  it "should validate inner contexts" do
    # acceptable
    should.not.raise(Lang::ContextError) do
      @branch.validate([Lang::VariableBindingDeclaration])
    end

    # unacceptable
    should.raise(Lang::ContextError) do
      @branch.validate([Lang::PackageBindingDeclaration])
    end
  end

  it "should evaluate and return suitable context" do
    env1 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env1, "$x := 1")

    env2 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env2, "$x := 2")

    # branch
    @branch.eval(env1).should == @branch.true_context
    @branch.eval(env2).should == @branch.else_context

    # branch without else context
    @branch_without_else.eval(env1).should == @branch_without_else.true_context
    @branch_without_else.eval(env2).should == @branch_without_else.else_context

    # fake branch
    @fake_branch.eval(env1).should == @fake_branch.true_context
    @fake_branch.eval(env2).should == @fake_branch.true_context
  end

  it "should raise structural error when condition is not boolean" do
    should.raise(Lang::StructuralError) do
      @invalid_branch.eval(TestHelper::Lang.env)
    end
  end
end

describe "Pione::Lang::CaseBranch" do
  before do
    @branch = TestHelper::Lang.conditional_branch(<<-STRING)
      case $x
      when 1
        $y := 1
      when 2
        $y := 2
      else
        $y := 3
      end
    STRING

    @branch_without_else = TestHelper::Lang.conditional_branch(<<-STRING)
      case $x
      when 1
        $y := 1
      when 2
        $y := 2
      end
    STRING

    @sequential = TestHelper::Lang.conditional_branch(<<-STRING)
      case $x
      when 1 | 2 | 3
        $y := 1
      when (1 | 2 | 3).all
        $y := 2
      else
        $y := 3
      end
    STRING
  end

  it "should get expr" do
    @branch.expr.should == TestHelper::Lang.expr("$x")
  end

  it "should get when_contexts" do
    @branch.when_contexts.size.should == 2
  end

  it "should get else context" do
    @branch.else_context.should == TestHelper::Lang.conditional_branch_context("$y := 3")
  end

  it "should get contexts" do
    env1 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env1, "$x := 1")

    env2 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env2, "$x := 2")

    env3 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env3, "$x := 3")

    env4 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env4, "$x := 1 | 2 | 3")

    env5 = TestHelper::Lang.env
    TestHelper::Lang.declaration!(env5, "$x := (1 | 2 | 3).all")

    @branch.eval(env1).should == @branch.when_contexts[0][1]
    @branch.eval(env2).should == @branch.when_contexts[1][1]
    @branch.eval(env3).should == @branch.else_context
    @branch.eval(env4).should == @branch.when_contexts[0][1]
    @branch.eval(env5).should == @branch.else_context

    @branch_without_else.eval(env1).should == @branch_without_else.when_contexts[0][1]
    @branch_without_else.eval(env2).should == @branch_without_else.when_contexts[1][1]
    @branch_without_else.eval(env3).should == Lang::ConditionalBranchContext.new([])
    @branch_without_else.eval(env4).should == @branch_without_else.when_contexts[0][1]
    @branch_without_else.eval(env5).should == Lang::ConditionalBranchContext.new([])

    @sequential.eval(env1).should == @sequential.when_contexts[0][1]
    @sequential.eval(env2).should == @sequential.when_contexts[0][1]
    @sequential.eval(env3).should == @sequential.when_contexts[0][1]
    @sequential.eval(env4).should == @sequential.when_contexts[0][1]
    @sequential.eval(env5).should == @sequential.when_contexts[1][1]
  end
end

