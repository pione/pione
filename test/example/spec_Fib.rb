require 'pione/test-helper'

describe "example/Fib" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should get a result with no parameters (default fib(3))"
    runner.args = ["example/Fib/Fib.pione", *runner.default_arguments]
    runner.run do |base|
      (base + "output" + "result.txt").should.exist
      (base + "output" + "result.txt").read.should.start_with "2"
    end
  end

  # FIXME: this test is unstable... maybe there are bugs

  # it "should get a result of fib(10)" do
  #   path = Temppath.create
  #   args = ["example/Fib/Fib.pione", "-o", path.to_s, "--params", "{NUM: 10}"]
  #   res = TestHelper::Command.succeed do
  #     Pione::Command::PioneClient.run(args)
  #   end
  #   Location[path + "result.txt"].should.exist
  #   Location[path + "result.txt"].read.should.start_with "55"
  # end
end
