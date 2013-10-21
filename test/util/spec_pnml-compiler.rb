require 'pione/test-helper'

TestHelper.scope do |this|
  this::PNML1 = Location[File.dirname(__FILE__)] + "data" + "pnml" + "Sequence.pnml"

  describe Pione::Util::PNMLCompiler do
    it "should compile from PNML to PIONE" do
      pione = Util::PNMLCompiler.new(this::PNML1).compile
      env = Lang::Environment.new.setup_new_package("Test")
      TestHelper::Lang.package_context!(env, pione)
      rule_a = env.rule_get(Lang::RuleExpr.new("A"))
      cond_a = rule_a.rule_condition_context.eval(env)
      cond_a.inputs.should == [Lang::DataExprSequence.of("i1")]
      cond_a.outputs.should == [Lang::DataExprSequence.of("p1")]
      rule_b = env.rule_get(Lang::RuleExpr.new("B"))
      cond_b = rule_b.rule_condition_context.eval(env)
      cond_b.inputs.should == [Lang::DataExprSequence.of("p1")]
      cond_b.outputs.should == [Lang::DataExprSequence.of("o1")]
    end
  end
end
