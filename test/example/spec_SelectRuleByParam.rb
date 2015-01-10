require 'pione/test-helper'

describe "example/SelectRuleByParam" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of scenario a of example/SelectRuleByParam"
    runner.args = ["example/SelectRuleByParam", "--rehearse", "Select A", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "message.txt").should.exist
      (base + "output" + "message.txt").read.chomp.should == "This is rule A."
    end
  end

  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of scenario b of example/SelectRuleByParam"
    runner.args = ["example/SelectRuleByParam", "--rehearse", "Select B", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "message.txt").should.exist
      (base + "output" + "message.txt").read.chomp.should == "This is rule B."
    end
  end

  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of scenario c of example/SelectRuleByParam"
    runner.args = ["example/SelectRuleByParam", "--rehearse", "Select C", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "message.txt").should.exist
      (base + "output" + "message.txt").read.chomp.should == "This is rule C."
    end
  end
end
