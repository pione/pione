require 'pione/test-helper'

describe Pione::Command::PioneActionExec do
  before do
    @cmd = Pione::Command::PioneActionExec
    @dir = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"
  end

  it "should execute action" do
    base = Location[Temppath.mkdir]
    args = [(@dir + "HelloWorld.md").path.to_s, "SayHello", "-d", base.path.to_s]
    cmd = @cmd.new(args)
    Rootage::ScenarioTest.succeed(cmd)
    (base + "message.txt").read.chomp.should == "Hello, world!"
  end
end
