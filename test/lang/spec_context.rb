require 'pione/test-helper'

describe "Pione::Lang::ConditionalBranchContext" do
  before do
    @env = TestHelper::Lang.env
  end

  describe "in package context" do
    it "should inherit acceptance from parent context" do
      should.raise(Lang::ContextError) do
        TestHelper::Lang.package_context!(@env, <<-PIONE)
          $X := true
          if $X
            rule A
          end
        PIONE
      end
    end
  end

  describe "in parameter context" do
    it "should inherit acceptance from parent context" do
      should.raise(Lang::ContextError) do
        TestHelper::Lang.context(<<-PIONE)
          Param
            if true; rule $X; end
          End
        PIONE
      end
    end
  end

  describe "in rule condition context" do
    it "should inherit acceptance from parent context" do
      should.raise(Lang::ContextError) do
        TestHelper::Lang.package_context!(@env, <<-PIONE)
          $X := true
          Rule R
            input '*.i'
            output '*.o'
            if $X
              rule A
            end
          Flow
            rule B
          End
        PIONE
      end
    end
  end

  describe "in flow context" do
    it "should inherit acceptance from parent context" do
      should.raise(Lang::ContextError) do
        TestHelper::Lang.package_context!(@env, <<-PIONE)
          $X := true
          Rule R
            input '*.i'
            output '*.o'
          Flow
            if $X
              param $P
            end
            rule B
          End
        PIONE
      end
    end

    it "should make branch by if" do
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R
          input '*.i'
          output '*.o'
        Flow
          if $X
            rule A
          end
          rule B
        End
      PIONE
      definition = @env.rule_get(Lang::RuleExpr.new("R"))

      # X := true
      env_true = @env.layer
      env_true.variable_set(Lang::Variable.new("X"), Lang::BooleanSequence.of(true))
      rule_set_true = definition.flow_context.eval(env_true)

      # X := false
      env_false = @env.layer
      env_false.variable_set(Lang::Variable.new("X"), Lang::BooleanSequence.of(false))
      rule_set_false = definition.flow_context.eval(env_false)

      # test
      rule_set_true.rules.pieces.size.should == 2
      rule_set_true.rules.pieces.should.include Lang::RuleExpr.new("A")
      rule_set_true.rules.pieces.should.include Lang::RuleExpr.new("B")
      rule_set_false.rules.pieces.size.should == 1
      rule_set_false.rules.should == TestHelper::Lang.expr!(@env, "B")
    end

    it "should make branch by if-then-else" do
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R
          input '*.i'
          output '*.o'
        Flow
          if $X
            rule A
          else
            rule B
          end
        End
      PIONE
      definition = @env.rule_get(Lang::RuleExpr.new("R"))

      # X := true
      env_true = @env.layer
      env_true.variable_set(Lang::Variable.new("X"), Lang::BooleanSequence.of(true))
      rule_set_true = definition.flow_context.eval(env_true)

      # X := false
      env_false = @env.layer
      env_false.variable_set(Lang::Variable.new("X"), Lang::BooleanSequence.of(false))
      rule_set_false = definition.flow_context.eval(env_false)

      # test
      rule_set_true.rules.pieces.size.should == 1
      rule_set_true.rules.should == TestHelper::Lang.expr!(@env, "A")
      rule_set_false.rules.pieces.size.should == 1
      rule_set_false.rules.should == TestHelper::Lang.expr!(@env, "B")
    end
  end
end

describe "Pione::Lang::ParamContext" do

end

describe "Pione::Lang::RuleConditionContext" do
  before do
    @env = TestHelper::Lang.env
  end

  it "should get context error" do
    should.raise(Lang::ContextError) do
      TestHelper::Lang.package_context!(@env, <<-PIONE)
        Rule R
          rule A
        Flow
          rule B
        End
      PIONE
    end
  end
end

describe "Pione::Lang::FlowContext" do
  before do
    @env = TestHelper::Lang.env
  end

  it "should be able to refer variables which are bound in package context" do
    TestHelper::Lang.package_context!(@env, <<-PIONE)
      $X := R1
      $Y := 10

      Rule R
        input '*.i'
        output '*.o'
      Flow
        rule $X
        rule R2 {Y: $Y}
      End
    PIONE
    definition = @env.rule_get(Lang::RuleExpr.new("R"))
    rule_condition = definition.rule_condition_context.eval(@env)
    rule_set = definition.flow_context.eval(@env)

    # test
    @env.variable_get(Lang::Variable.new("X")).should == TestHelper::Lang.expr!(@env, "R1")
    @env.variable_get(Lang::Variable.new("Y")).should == TestHelper::Lang.expr!(@env, "10")
    rule_set.rules.pieces.size.should == 2
    rule_set.rules.should == TestHelper::Lang.expr!(@env, "R1 | (R2 {Y: 10})")
  end

  it "should be able to refer variables which are bound in rule condition context" do
    TestHelper::Lang.package_context!(@env, <<-PIONE)
      Rule R
        input '*.i'
        output '*.o'
        $X := R1
        $Y := 10
      Flow
        rule $X
        rule R2 {Y: $Y}
      End
    PIONE
    definition = @env.rule_get(Lang::RuleExpr.new("R"))
    rule_condition = definition.rule_condition_context.eval(@env)
    rule_set = definition.flow_context.eval(@env)

    # test
    @env.variable_get(Lang::Variable.new("X")).should == TestHelper::Lang.expr!(@env, "R1")
    @env.variable_get(Lang::Variable.new("Y")).should == TestHelper::Lang.expr!(@env, "10")
    rule_set.rules.pieces.size.should == 2
    rule_set.rules.should == TestHelper::Lang.expr!(@env, "R1 | (R2 {Y: 10})")
  end

  it "should be able to refer variables which are bound in flow context" do
    TestHelper::Lang.package_context!(@env, <<-PIONE)
      Rule R
        input '*.i'
        output '*.o'
      Flow
        $X := R1
        $Y := 10
        rule $X
        rule R2 {Y: $Y}
      End
    PIONE
    definition = @env.rule_get(Lang::RuleExpr.new("R"))
    rule_condition = definition.rule_condition_context.eval(@env)
    rule_set = definition.flow_context.eval(@env)

    # test
    @env.variable_get(Lang::Variable.new("X")).should == TestHelper::Lang.expr!(@env, "R1")
    @env.variable_get(Lang::Variable.new("Y")).should == TestHelper::Lang.expr!(@env, "10")
    rule_set.rules.pieces.size.should == 2
    rule_set.rules.should == TestHelper::Lang.expr!(@env, "R1 | (R2 {Y: 10})")
  end
end

describe "Pione::Lang::PackageContext" do

end

describe "Pione::Lang::ActionContext" do

end

