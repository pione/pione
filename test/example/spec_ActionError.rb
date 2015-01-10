require 'pione/test-helper'

describe "example/ActionError" do
  TestHelper::PioneClientRunner.test(self) do |runner|
    runner.title = "should fail in execution of example/ActionError"
    runner.args = ["example/ActionError", *runner.default_arguments]
    runner.fail
  end
end
