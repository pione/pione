require 'pione/test-helper'

describe "example/OddSelector" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of example/OddSelector"
    runner.args = ["example/OddSelector", "--rehearse", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "1.res").should.exist
      (base + "output" + "2.res").should.not.exist
      (base + "output" + "3.res").should.exist
      (base + "output" + "4.res").should.not.exist
      (base + "output" + "5.res").should.exist
      (base + "output" + "6.res").should.not.exist
      (base + "output" + "7.res").should.exist
      (base + "output" + "8.res").should.not.exist
      (base + "output" + "9.res").should.exist
      (base + "output" + "10.res").should.not.exist
    end
  end
end
