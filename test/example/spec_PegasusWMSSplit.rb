require 'pione/test-helper'

describe "example/PegasusWMS/Split" do
  if TestHelper::InternetConnectivity.ok?
    TestHelper::PioneClientRunner.test(self) do |runner|
      runner.title = "should get a result of example/PegasusWMS/Split"
      runner.args = ["example/PegasusWMS/Split/", *runner.default_arguments]
      runner.run do |base|
        (base + "output" + "count.txt.a").should.exist
        (base + "output" + "count.txt.a").size.should > 0
        (base + "output" + "count.txt.b").should.exist
        (base + "output" + "count.txt.b").size.should > 0
        (base + "output" + "count.txt.c").should.exist
        (base + "output" + "count.txt.c").size.should > 0
        (base + "output" + "count.txt.d").should.exist
        (base + "output" + "count.txt.d").size.should > 0
      end
    end
  else
    puts "    * ignored because of no internet connection"
  end
end
