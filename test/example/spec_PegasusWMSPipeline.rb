require 'pione/test-helper'

describe "example/PegasusWMS/Pipeline" do
  if TestHelper::InternetConnectivity.ok?
    TestHelper::PioneClientRunner.test(self) do |runner|
      runner.title = "should get a result of example/PegasusWMS/Pipeline"
      runner.args = ["example/PegasusWMS/Pipeline/", *runner.default_arguments]
      runner.run do |base|
        (base + "output" + "count.txt").should.exist
        (base + "output" + "count.txt").size.should > 0
      end
    end
  else
    puts "    * ignored because of no internet connection"
  end
end
