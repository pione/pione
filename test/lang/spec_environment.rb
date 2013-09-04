require_relative '../test-util'

describe 'Pione::Lang::Environment' do
  before do
    @env = TestUtil::Lang.env
  end

  it 'should update variable table' do
    # declare a variable in current package
    TestUtil::Lang.declaration!(@env, "$x := 1")

    # declare a variable in other package
    TestUtil::Lang.declaration!(@env, "package $p <- &Test")
    TestUtil::Lang.declaration!(@env, "$p.var($y) := 2")

    # test
    TestUtil::Lang.expr!(@env, "$x").should == IntegerSequence.of(1)
    TestUtil::Lang.expr!(@env, "$p.var($y)").should  == IntegerSequence.of(2)
  end

  it 'should append new package' do
    # append a package
    TestUtil::Lang.declaration!(@env, "package $p <- &Test")

    # test
    child_id = @env.variable_get(Variable.new("p")).pieces.first.package_id
    definition = @env.package_get(PackageExpr.new(package_id: child_id))
    definition.parent_id.should == @env.current_package_id
  end

  it 'should delegate to find variable' do
    # create a new package
    TestUtil::Lang.declaration!(@env, "package $p <- &Test")

    # bind variables in the parent package
    TestUtil::Lang.declaration!(@env, "$x := 1")

    # test
    TestUtil::Lang.expr!(@env, "$x").should == IntegerSequence.of(1)
    TestUtil::Lang.expr!(@env, "$p.var($x)").should == IntegerSequence.of(1)
  end

  it 'should override parent variable by the child' do
    # bind package
    TestUtil::Lang.declaration!(@env, "package $p <- &Test")

    # bind variables
    TestUtil::Lang.declaration!(@env, "$x := 1")
    TestUtil::Lang.declaration!(@env, "$p.var($x) := 2")

    # test
    TestUtil::Lang.expr!(@env, "$x").should == IntegerSequence.of(1)
    TestUtil::Lang.expr!(@env, "$p.var($x)").should == IntegerSequence.of(2)
  end

  it "should get rule" do
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R1
        input '*.i'
        output '{$*}.o'.touch
        param $X := 1
      End

      rule R2 := R1 {X: 2}
    CONTEXT

    # test
    r1 = @env.rule_get(Model::RuleExpr.new("R1"))
    r2 = @env.rule_get(Model::RuleExpr.new("R2"))
    r1.rule_condition_context.should == r2.rule_condition_context
    r1.param_sets.should == TestUtil::Lang.expr!(@env, "{}")
    r2.param_sets.should == TestUtil::Lang.expr!(@env, "{X: 2}")
  end

  it 'should delegate to find rule' do
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      package $p <- &Test

      Rule R1
        input '*.i'
        output '{$*}.o'.touch
        param $X := 1
      End

      rule R2 := R1 {X: 2}
    CONTEXT

    # test
    r1 = @env.rule_get(Model::RuleExpr.new("R1"))
    pr1 = @env.rule_get(TestUtil::Lang.expr!(@env, "$p.rule(R1)").pieces.first)
    pr2 = @env.rule_get(TestUtil::Lang.expr!(@env, "$p.rule(R2)").pieces.first)
    pr1.rule_condition_context.should == r1.rule_condition_context
    pr2.rule_condition_context.should == r1.rule_condition_context
    pr1.param_sets.should == TestUtil::Lang.expr!(@env, "{}")
    pr2.param_sets.should == TestUtil::Lang.expr!(@env, "{X: 2}")
  end

  it 'should override parent rule by the child' do
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      package $p <- &Test

      Rule R
        input '*.i'
        output '{$*}.o'.touch
        param $X := 1
      End

      rule R1 := R {X: 2}

      Rule $p.rule(R)
        input '*.i'
        output '{$*}.o'.touch
        param $X := 3
      End

      rule $p.rule(R1) := $p.rule(R) {X: 4}
    CONTEXT

    # test
    r = @env.rule_get(Model::RuleExpr.new("R"))
    pr = @env.rule_get(TestUtil::Lang.expr!(@env, "$p.rule(R)").pieces.first)
    pr1 = @env.rule_get(TestUtil::Lang.expr!(@env, "$p.rule(R1)").pieces.first)
    pr.rule_condition_context.should != r.rule_condition_context
    pr1.rule_condition_context.should != r.rule_condition_context
    pr.param_sets.should == TestUtil::Lang.expr!(@env, "{}")
    pr1.param_sets.should == TestUtil::Lang.expr!(@env, "{X: 4}")
  end
end

