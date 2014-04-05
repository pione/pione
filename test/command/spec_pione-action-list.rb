require 'pione/test-helper'

describe Pione::Command::PioneActionList do
  before do
    @cmd = Pione::Command::PioneActionList
    @dir = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"
  end

  it "should show action names" do
    cmd = @cmd.new([(@dir + "D1.md").path.to_s])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.should == "Name1\nName2"
  end

  it "should show action names in compact form" do
    cmd = @cmd.new(["--compact", (@dir + "D1.md").path.to_s])
    res = Rootage::ScenarioTest.succeed(cmd)
    res.stdout.string.chomp.should == "Name1 Name2"
  end
end
