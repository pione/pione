require_relative '../test-util'

describe "Pione::Lang::VariableBindingDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.declaration!(@env, "package $p <- &Test")

    @cx = TestUtil::Lang.declaration("$x := 1")
    @cy = TestUtil::Lang.declaration("$y := $x")
    @cz = TestUtil::Lang.declaration("$z := $p.var($x)")
    @px = TestUtil::Lang.declaration("$p.var($x) := 2")
    @py = TestUtil::Lang.declaration("$p.var($y) := $y")
    @pz = TestUtil::Lang.declaration("$p.var($z) := $p.var($x)")
  end

  it "should get expr1" do
    @cx.expr1.should == TestUtil::Lang.expr("$x")
  end

  it "should get expr2" do
    @cx.expr2.should == TestUtil::Lang.expr("1")
  end

  it "should update variable table by evaluating" do
    @cx.eval(@env)
    @cy.eval(@env)
    @cz.eval(@env)
    @px.eval(@env)
    @py.eval(@env)
    @pz.eval(@env)

    TestUtil::Lang.expr!(@env, "$x").should == TestUtil::Lang.expr("1")
    TestUtil::Lang.expr!(@env, "$y").should == TestUtil::Lang.expr("1")
    TestUtil::Lang.expr!(@env, "$z").should == TestUtil::Lang.expr("2")
    TestUtil::Lang.expr!(@env, "$p.var($x)").should == TestUtil::Lang.expr("2")
    TestUtil::Lang.expr!(@env, "$p.var($y)").should == TestUtil::Lang.expr("1")
    TestUtil::Lang.expr!(@env, "$p.var($z)").should == TestUtil::Lang.expr("2")
  end

  it "should permit to be in arbitrary order" do
    env1 = TestUtil::Lang.env
    @cx.eval(env1)
    @cy.eval(env1)

    env2 = TestUtil::Lang.env
    @cy.eval(env2)
    @cx.eval(env2)

    TestUtil::Lang.expr!(env1, "$x").should == TestUtil::Lang.expr!(env2, "$x")
    TestUtil::Lang.expr!(env1, "$y").should == TestUtil::Lang.expr!(env2, "$y")
  end

  it "should detect rebind" do
    @cx.eval!(@env)
    should.raise(Lang::RebindError) do
      TestUtil::Lang.declaration!(@env, "$x := 2")
    end
  end

  it "should detect variable loop" do
    TestUtil::Lang.declaration!(@env, "$c1 := $c2")
    TestUtil::Lang.declaration!(@env, "$c2 := $c3")
    TestUtil::Lang.declaration!(@env, "$c3 := $c1")

    should.raise(Lang::CircularReferenceError) {TestUtil::Lang.expr!(@env, "$c1")}
    should.raise(Lang::CircularReferenceError) {TestUtil::Lang.expr!(@env, "$c2")}
    should.raise(Lang::CircularReferenceError) {TestUtil::Lang.expr!(@env, "$c3")}
  end
end

describe "Pione::Lang::PackageBindingDeclaration" do
  before do
    @env = TestUtil::Lang.env
    @p1 = TestUtil::Lang.declaration("package $p1 <- &Test")
    @p2 = TestUtil::Lang.declaration("package $p2 <- $p1")
    @p3 = TestUtil::Lang.declaration("package $p3 <- $p2")
  end

  it "should get expr1" do
    @p1.expr1.should == TestUtil::Lang.expr("$p1")
  end

  it "should get expr2" do
    @p1.expr2.should == TestUtil::Lang.expr("&Test")
  end

  it "should generate packages" do
    should.not.raise do
      @p1.eval!(@env)
      @p2.eval!(@env)
      @p3.eval!(@env)
      TestUtil::Lang.expr!(@env, "$p1")
      TestUtil::Lang.expr!(@env, "$p2")
      TestUtil::Lang.expr!(@env, "$p3")
    end
  end

  it "should permit to be in arbitrary order" do
    should.not.raise do
      TestUtil::Lang.package_context!(@env, <<-CONTEXT)
        package $p3 <- $p2
        package $p2 <- $p1
        package $p1 <- &Test
      CONTEXT
      TestUtil::Lang.expr!(@env, "$p1")
      TestUtil::Lang.expr!(@env, "$p2")
      TestUtil::Lang.expr!(@env, "$p3")
    end
  end

  it "should detect package rebinding" do
    @p1.eval!(@env)
    should.raise(Lang::RebindError) {@p1.eval!(@env)}
  end

  it "should set paramter set" do
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      param $X := 1
      param $Y := 2
      param $Z := 3
      package $p1 <- &Test
      package $p2 <- $p1 {X: 10}
      package $p3 <- $p2 {Y: 20}
      package $p4 <- $p3 {Z: 30}
    CONTEXT
    TestUtil::Lang.expr!(@env, "$p1.param").should == Lang::ParameterSetSequence.new
    TestUtil::Lang.expr!(@env, "$p2.param").should == TestUtil::Lang.expr!(@env, "{X: 10}")
    TestUtil::Lang.expr!(@env, "$p3.param").should == TestUtil::Lang.expr!(@env, "{X: 10, Y: 20}")
    TestUtil::Lang.expr!(@env, "$p4.param").should == TestUtil::Lang.expr!(@env, "{X: 10, Y: 20, Z: 30}")
  end
end

describe "Pione::Lang::ParamDeclaration" do
  describe "package context" do
    before do
      @env = TestUtil::Lang.env
      @x = TestUtil::Lang.declaration("param $X := 1")
      @y = TestUtil::Lang.declaration("basic param $Y := 1 + 1")
      @z = TestUtil::Lang.declaration("advanced param $Z := 1 + 1 + 1")
    end

    it "should get expr1" do
      @x.expr1.should == TestUtil::Lang.expr("$X")
      @y.expr1.should == TestUtil::Lang.expr("$Y")
      @z.expr1.should == TestUtil::Lang.expr("$Z")
    end

    it "should get expr2" do
      @x.expr2.should == TestUtil::Lang.expr("1")
      @y.expr2.should == TestUtil::Lang.expr("1 + 1")
      @z.expr2.should == TestUtil::Lang.expr("1 + 1 + 1")
    end

    it "should set parameters" do
      @x.eval(@env)
      @y.eval(@env)
      @z.eval(@env)
      definition = @env.package_table.get(Lang::PackageExpr.new(package_id: @env.current_package_id))
      definition.param_definition["X"].type.should == :basic
      definition.param_definition["X"].value.should == TestUtil::Lang.expr("1")
      definition.param_definition["Y"].type.should == :basic
      definition.param_definition["Y"].value.should == TestUtil::Lang.expr("1 + 1")
      definition.param_definition["Z"].type.should == :advanced
      definition.param_definition["Z"].value.should == TestUtil::Lang.expr("1 + 1 + 1")
    end

    it "should be disable to set parameter in other packages" do
      should.raise(Lang::ParamDeclarationError) do
        TestUtil::Lang.package_context!(@env, <<-CONTEXT)
          package $p1 <- &Test
          param $p1.var($X) := 1
        CONTEXT
      end
    end

    it "should permit to be in arbitrary order" do
      should.not.raise(Lang::LangError) do
        TestUtil::Lang.package_context!(@env, <<-CONTEXT)
          param $X := $Y
          param $Y := $Z
          param $Z := 1
        CONTEXT
      end
    end

    it "should get default values" do
      @x.eval(@env)
      @y.eval(@env)
      @z.eval(@env)
      TestUtil::Lang.expr!(@env, "$X").should == Lang::IntegerSequence.of(1)
      TestUtil::Lang.expr!(@env, "$Y").should == Lang::IntegerSequence.of(2)
      TestUtil::Lang.expr!(@env, "$Z").should == Lang::IntegerSequence.of(3)
    end
  end

  describe "rule condition context" do
    before do
      @env = TestUtil::Lang.env
      TestUtil::Lang.package_context!(@env, <<-CONTEXT)
        Rule R
          input '*.i'
          output '{$*}.o'
          param $X := 1
          basic param $Y := 2
          advanced param $Z := 3
        End
      CONTEXT
    end

    it "should get params" do
      condition = @env.rule_get(Lang::RuleExpr.new("R")).rule_condition_context.eval(@env)
      condition.param_definition.size.should == 3
      condition.param_definition["X"].type.should == :basic
      condition.param_definition["X"].value.should == Lang::IntegerSequence.of(1)
      condition.param_definition["Y"].type.should == :basic
      condition.param_definition["Y"].value.should == Lang::IntegerSequence.of(2)
      condition.param_definition["Z"].type.should == :advanced
      condition.param_definition["Z"].value.should == Lang::IntegerSequence.of(3)
    end
  end
end

describe "Pione::Lang::RuleBindingDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
        param $X := 1
        param $Y := 2
        param $Z := 3
      End
    CONTEXT
    @r1 = TestUtil::Lang.declaration("rule R1 := R  {X: 10}")
    @r2 = TestUtil::Lang.declaration("rule R2 := R1 {Y: 20}")
    @r3 = TestUtil::Lang.declaration("rule R3 := R2 {Z: 30}")
  end

  it "should get expr1" do
    @r1.expr1.should == TestUtil::Lang.expr("R1")
  end

  it "should get expr2" do
    @r1.expr2.should == TestUtil::Lang.expr("R {X: 10}")
  end

  it "should set rules" do
    @r1.eval(@env)
    @r2.eval(@env)
    @r3.eval(@env)
    @env.rule_get(Lang::RuleExpr.new("R1")).param_sets.should == TestUtil::Lang.expr!(@env, "{X: 10}")
    @env.rule_get(Lang::RuleExpr.new("R2")).param_sets.should == TestUtil::Lang.expr!(@env, "{X: 10, Y: 20}")
    @env.rule_get(Lang::RuleExpr.new("R3")).param_sets.should == TestUtil::Lang.expr!(@env, "{X: 10, Y: 20, Z: 30}")
  end

  it "should permit to be in arbitrary order" do
    should.not.raise(Lang::LangError) do
      TestUtil::Lang.package_context!(@env, <<-CONTEXT)
        rule R1 := R2 {X: 10}
        rule R2 := R3 {Y: 20}
        rule R3 := R  {Z: 30}
      CONTEXT
    end
  end
end

describe "Pione::Lang::ConstituentRuleDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
      Flow
        rule A
        rule B {X: 1}
        rule C {X: 1, Y: 2}
      End
    CONTEXT
  end

  it "should get constituent rules" do
    definition = @env.rule_get(Lang::RuleExpr.new("R"))
    rule_set = definition.flow_context.eval(@env)
    rule_set.rules.size.should == 3
    rule_set.rules.should == TestUtil::Lang.expr!(@env, "A | (B {X: 1}) | (C {X: 1, Y: 2})")
  end
end

describe "Pione::Lang::InnputDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i1'
        input '{$*}.i2'
        input '{$*}.i3'
        output '{$*}.o'
      End
    CONTEXT
  end

  it "should get inputs" do
    condition = @env.rule_get(Lang::RuleExpr.new("R")).rule_condition_context.eval(@env)
    condition.inputs.size.should == 3
    condition.inputs.should.include TestUtil::Lang.expr("'*.i1'")
    condition.inputs.should.include TestUtil::Lang.expr("'{$*}.i2'")
    condition.inputs.should.include TestUtil::Lang.expr("'{$*}.i3'")
  end
end

describe "Pione::Lang::OutputDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o1'
        output '{$*}.o2'
        output '{$*}.o3'
      End
    CONTEXT
  end

  it "should get outputs" do
    condition = @env.rule_get(Lang::RuleExpr.new("R")).rule_condition_context.eval(@env)
    condition.outputs.size.should == 3
    condition.outputs.should.include TestUtil::Lang.expr("'{$*}.o1'")
    condition.outputs.should.include TestUtil::Lang.expr("'{$*}.o2'")
    condition.outputs.should.include TestUtil::Lang.expr("'{$*}.o3'")
  end
end

describe "Pione::Lang::FeatureDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
        feature +F1
        feature -F2
        feature ?F3
      End
    CONTEXT
  end

  it "should get features" do
    condition = @env.rule_get(Lang::RuleExpr.new("R")).rule_condition_context.eval(@env)
    condition.features.size.should == 3
    condition.features.should.include TestUtil::Lang.expr("+F1")
    condition.features.should.include TestUtil::Lang.expr("-F2")
    condition.features.should.include TestUtil::Lang.expr("?F3")
  end
end

describe "Pione::Lang::ConstraintDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
        constraint 1 > 0
        constraint 1 < 0
        constraint $X == 1
      End
    CONTEXT
  end

  it "should get constraints" do
    condition = @env.rule_get(Lang::RuleExpr.new("R")).rule_condition_context.eval(@env)
    condition.constraints.size.should == 3
    condition.constraints.should.include TestUtil::Lang.expr("1 > 0")
    condition.constraints.should.include TestUtil::Lang.expr("1 < 0")
    condition.constraints.should.include TestUtil::Lang.expr("$X == 1")
  end
end

describe "Pione::Lang::AnnotationDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
        @. "annotation1"
        @. "annotation2"
        @. "annotation3"
      End
    CONTEXT
  end

  it "should get constraints" do
    condition = @env.rule_get(Lang::RuleExpr.new("R")).rule_condition_context.eval(@env)
    condition.annotations.size.should == 3
    condition.annotations.should.include TestUtil::Lang.expr('"annotation1"')
    condition.annotations.should.include TestUtil::Lang.expr('"annotation2"')
    condition.annotations.should.include TestUtil::Lang.expr('"annotation3"')
  end
end

describe "Pione::Lang::ExprDeclaration" do
  before do
    @env = TestUtil::Lang.env
  end

  it "should get the result" do
    TestUtil::Lang.declaration!(@env, "? 1 + 2").should == Lang::IntegerSequence.of(3)
  end
end

describe "Pione::Lang::ParamBlockDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Param
        $X1 := 1
        $X2 := 2
        $X3 := 3
      End

      Basic Param
        $Y1 := 1 + 1
        $Y2 := 1 + 1 + 1
        $Y3 := 1 + 1 + 1 + 1
      End

      Advanced Param
        $Z1 := 1
        $Z2 := 2
        $Z3 := 3
      End
    CONTEXT
  end

  it "should get parameters" do
    definition = @env.package_table.get(Lang::PackageExpr.new(package_id: @env.current_package_id))
    definition.param_definition["X1"].type.should == :basic
    definition.param_definition["X1"].value.should == TestUtil::Lang.expr("1")
    definition.param_definition["X2"].type.should == :basic
    definition.param_definition["X2"].value.should == TestUtil::Lang.expr("2")
    definition.param_definition["X3"].type.should == :basic
    definition.param_definition["X3"].value.should == TestUtil::Lang.expr("3")
    definition.param_definition["Y1"].type.should == :basic
    definition.param_definition["Y1"].value.should == TestUtil::Lang.expr("1 + 1")
    definition.param_definition["Y2"].type.should == :basic
    definition.param_definition["Y2"].value.should == TestUtil::Lang.expr("1 + 1 + 1")
    definition.param_definition["Y3"].type.should == :basic
    definition.param_definition["Y3"].value.should == TestUtil::Lang.expr("1 + 1 + 1 + 1")
    definition.param_definition["Z1"].type.should == :advanced
    definition.param_definition["Z1"].value.should == TestUtil::Lang.expr("1")
    definition.param_definition["Z2"].type.should == :advanced
    definition.param_definition["Z2"].value.should == TestUtil::Lang.expr("2")
    definition.param_definition["Z3"].type.should == :advanced
    definition.param_definition["Z3"].value.should == TestUtil::Lang.expr("3")
  end
end

describe "Pione::Lang::FlowRuleDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
      Flow
        $X := 10
        rule A
        rule B {X: $X}
        rule C {Y: 20}
      End
    CONTEXT
  end

  it "should get flow rule" do
    definition = @env.rule_get(Lang::RuleExpr.new("R"))
    condition = definition.rule_condition_context.eval(@env)
    condition.inputs.size.should == 1
    condition.inputs[0].should == TestUtil::Lang.expr("'*.i'")
    condition.outputs.size.should == 1
    condition.outputs[0].should == TestUtil::Lang.expr("'{$*}.o'")
    rule_set = definition.flow_context.eval(@env)
    rule_set.rules.size.should == 3
    rule_set.rules.should == TestUtil::Lang.expr!(@env, "A | (B {X: $X}) | C {Y: 20}")
    TestUtil::Lang.expr!(@env, "$X").should == Lang::IntegerSequence.of(10)
  end
end

describe "Pione::Lang::ActionRuleDeclaration" do
  before do
    @env = TestUtil::Lang.env
    TestUtil::Lang.package_context!(@env, <<-CONTEXT)
      Rule R
        input '*.i'
        output '{$*}.o'
      Action
        cp {$I[1]} > {$O[1]}
      End
    CONTEXT
  end

  it "should get action rule" do
    definition = @env.rule_get(Lang::RuleExpr.new("R"))
    condition = definition.rule_condition_context.eval(@env)
    condition.inputs.size.should == 1
    condition.inputs[0].should == TestUtil::Lang.expr("'*.i'")
    condition.outputs.size.should == 1
    condition.outputs[0].should == TestUtil::Lang.expr("'{$*}.o'")
    action = definition.action_context.eval(@env)
    action.content.should == "cp {$I[1]} > {$O[1]}\n"
  end
end

