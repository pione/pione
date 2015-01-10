require 'pione/test-helper'

describe "example/PegasusWMS/Merge" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of example/PegasusWMS/Merge"
    runner.args = ["example/PegasusWMS/Merge/", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "binaries.txt").should.exist
      (base + "output" + "binaries.txt").size.should > 0
    end
  end
end
