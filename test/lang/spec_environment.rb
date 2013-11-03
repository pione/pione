require 'pione/test-helper'

describe 'Pione::Lang::Environment' do
  before do
    @env = TestHelper::Lang.env
  end

  it 'should update variable table' do
    # declare a variable in current package
    TestHelper::Lang.declaration!(@env, "$x := 1")

    # declare a variable in other package
    TestHelper::Lang.declaration!(@env, "package $p <- &Test")
    TestHelper::Lang.declaration!(@env, "$p.var($y) := 2")

    # test
    TestHelper::Lang.expr!(@env, "$x").should == Lang::IntegerSequence.of(1)
    TestHelper::Lang.expr!(@env, "$p.var($y)").should  == Lang::IntegerSequence.of(2)
  end

  it 'should get variable names by package ID' do
    @env = @env.setup_new_package("A")
    TestHelper::Lang.declaration!(@env, "$a := 1")
    @env = @env.setup_new_package("B", ["A"])
    TestHelper::Lang.declaration!(@env, "$b := 2")
    @env = @env.setup_new_package("C", ["B"])
    TestHelper::Lang.declaration!(@env, "$c := 3")
    @env = @env.setup_new_package("D")
    TestHelper::Lang.declaration!(@env, "$d := 4")
    @env = @env.setup_new_package("E", ["C", "D"])
    TestHelper::Lang.declaration!(@env, "$e := 4")

    @env.variable_table.select_names_by(@env, "A").sort.should == ["a"]
    @env.variable_table.select_names_by(@env, "B").sort.should == ["a", "b"]
    @env.variable_table.select_names_by(@env, "C").sort.should == ["a", "b", "c"]
    @env.variable_table.select_names_by(@env, "D").sort.should == ["d"]
    @env.variable_table.select_names_by(@env, "E").sort.should == ["a", "b", "c", "d", "e"]
  end

  it 'should append new package' do
    # append a package
    TestHelper::Lang.declaration!(@env, "package $p <- &Test")

    # test
    child_id = @env.variable_get(Lang::Variable.new("p")).pieces.first.package_id
    definition = @env.package_get(Lang::PackageExpr.new(package_id: child_id))
    definition.parent_ids.should == [@env.current_package_id]
  end

  it 'should delegate to find variable' do
    # create a new package
    TestHelper::Lang.declaration!(@env, "package $p <- &Test")

    # bind variables in the parent package
    TestHelper::Lang.declaration!(@env, "$x := 1")

    # test
    TestHelper::Lang.expr!(@env, "$x").should == Lang::IntegerSequence.of(1)
    TestHelper::Lang.expr!(@env, "$p.var($x)").should == Lang::IntegerSequence.of(1)
  end

  it 'should override parent variable by the child' do
    # bind package
    TestHelper::Lang.declaration!(@env, "package $p <- &Test")

    # bind variables
    TestHelper::Lang.declaration!(@env, "$x := 1")
    TestHelper::Lang.declaration!(@env, "$p.var($x) := 2")

    # test
    TestHelper::Lang.expr!(@env, "$x").should == Lang::IntegerSequence.of(1)
    TestHelper::Lang.expr!(@env, "$p.var($x)").should == Lang::IntegerSequence.of(2)
  end

  it "should get rule" do
    TestHelper::Lang.package_context!(@env, <<-CONTEXT)
      Rule R1
        input '*.i'
        output '{$*}.o'.touch
        param $X := 1
      End

      rule R2 := R1 {X: 2}
    CONTEXT

    # test
    r1 = @env.rule_get(Lang::RuleExpr.new("R1"))
    r2 = @env.rule_get(Lang::RuleExpr.new("R2"))
    r1.rule_condition_context.should == r2.rule_condition_context
    r1.param_sets.should == TestHelper::Lang.expr!(@env, "{}")
    r2.param_sets.should == TestHelper::Lang.expr!(@env, "{X: 2}")
  end

  it 'should delegate to find rule' do
    TestHelper::Lang.package_context!(@env, <<-CONTEXT)
      package $p <- &Test

      Rule R1
        input '*.i'
        output '{$*}.o'.touch
        param $X := 1
      End

      rule R2 := R1 {X: 2}
    CONTEXT

    # test
    r1 = @env.rule_get(Lang::RuleExpr.new("R1"))
    pr1 = @env.rule_get(TestHelper::Lang.expr!(@env, "$p.rule(R1)").pieces.first)
    pr2 = @env.rule_get(TestHelper::Lang.expr!(@env, "$p.rule(R2)").pieces.first)
    pr1.rule_condition_context.should == r1.rule_condition_context
    pr2.rule_condition_context.should == r1.rule_condition_context
    pr1.param_sets.should == TestHelper::Lang.expr!(@env, "{}")
    pr2.param_sets.should == TestHelper::Lang.expr!(@env, "{X: 2}")
  end

  it 'should override parent rule by the child' do
    TestHelper::Lang.package_context!(@env, <<-CONTEXT)
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
    r = @env.rule_get(Lang::RuleExpr.new("R"))
    pr = @env.rule_get(TestHelper::Lang.expr!(@env, "$p.rule(R)").pieces.first)
    pr1 = @env.rule_get(TestHelper::Lang.expr!(@env, "$p.rule(R1)").pieces.first)
    pr.rule_condition_context.should != r.rule_condition_context
    pr1.rule_condition_context.should != r.rule_condition_context
    pr.param_sets.should == TestHelper::Lang.expr!(@env, "{}")
    pr1.param_sets.should == TestHelper::Lang.expr!(@env, "{X: 4}")
  end
end

