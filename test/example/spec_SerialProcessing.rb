require 'pione/test-helper'

describe "example/SerialProcessing" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result of example/SerialProcessing"
    runner.args = ["example/SerialProcessing", "--rehearse", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "1.a").should.exist
      (base + "output" + "2.a").should.exist
      (base + "output" + "3.a").should.exist
      (base + "output" + "4.a").should.exist
      (base + "output" + "1.b").should.exist
      (base + "output" + "2.b").should.exist
      (base + "output" + "3.b").should.exist
      (base + "output" + "4.b").should.exist
      (base + "output" + "1.a").mtime.should <= (base + "output" + "2.a").mtime
      (base + "output" + "2.a").mtime.should <= (base + "output" + "3.a").mtime
      (base + "output" + "3.a").mtime.should <= (base + "output" + "4.a").mtime
      (base + "output" + "4.a").mtime.should <= (base + "output" + "1.b").mtime
      (base + "output" + "1.b").mtime.should <= (base + "output" + "2.b").mtime
      (base + "output" + "2.b").mtime.should <= (base + "output" + "3.b").mtime
      (base + "output" + "3.b").mtime.should <= (base + "output" + "4.b").mtime
    end
  end
end
