require 'pione/test-helper'

describe "example/Sum" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of example/Sum"
    runner.args = ["example/Sum", "--rehearse", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "sum.txt").should.exist
    end
  end
end
