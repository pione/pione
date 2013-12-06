require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"

  describe Pione::Command::PioneActionList do
    before do
      @cmd = Pione::Command::PioneActionList
    end

    it "should show action names" do
      args = [(this::DIR + "D1.md").path.to_s]
      res = TestHelper::Command.succeed(@cmd, args)
      res.stdout.string.chomp.should == "Name1\nName2"
    end
  end
end
