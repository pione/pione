require 'pione/test-helper'

TestHelper.scope do |this|
  this::PNML1 = Location[File.dirname(__FILE__)] + "data" + "pnml" + "Sequence.pnml"

  describe Pione::Util::PNMLCompiler do
    it "should compile from PNML to PIONE" do
      pione = Util::PNMLCompiler.new(this::PNML1, "Test", "E", "T").compile

      env = Lang::Environment.new.setup_new_package("Test")
      TestHelper::Lang.package_context!(env, pione)

      env.rule_get(Lang::RuleExpr.new("Main")).tap do |rule|
        cond = rule.rule_condition_context.eval(env)
        cond.inputs.should == [TestHelper::Lang.expr("'i1'")]
        cond.outputs.should == [TestHelper::Lang.expr("'o1'")]
      end

      env.rule_get(Lang::RuleExpr.new("A")).tap do |rule|
        cond = rule.rule_condition_context.eval(env)
        cond.inputs.should == [TestHelper::Lang.expr("'i1'")]
        cond.outputs.should == [TestHelper::Lang.expr("'p1'.touch")]
      end

      env.rule_get(Lang::RuleExpr.new("B")).tap do |rule|
        cond = rule.rule_condition_context.eval(env)
        cond.inputs.should == [TestHelper::Lang.expr("'p1'")]
        cond.outputs.should == [TestHelper::Lang.expr("'o1'.touch")]
      end
    end
  end
end
