require 'pione/test-helper'

describe "example/FeatureExample" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of example/FeatureExample"
    runner.args = ["example/FeatureExample", "--feature", "^X", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "message.txt").should.exist
      (base + "output" + "message.txt").read.chomp.should == "I can take the task."
    end
  end

  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should timeout with feature `*` in processing example/FeatureExample"
    runner.args = ["example/FeatureExample", "--feature", "*", *runner.default_arguments]
    runner.timeout(5)
  end
end
