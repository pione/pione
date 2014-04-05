require 'pione/test-helper'

describe Pione::Command::PioneActionPrint do
  before do
    @cmd = Pione::Command::PioneActionPrint
    @dir = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"
  end

  it "should print action contents" do
    cmd = @cmd.new([(@dir + "HelloWorld.md").path.to_s, "SayHello"])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.should == "echo \"Hello, world!\" > message.txt"
  end
end
