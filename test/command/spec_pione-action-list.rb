require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"

  describe Pione::Command::PioneActionList do
    it "should show action names" do
      args = [(this::DIR + "D1.md").path.to_s]
      res = TestHelper::Command.succeed do
        Pione::Command::PioneActionList.run(args)
      end
      res.stdout.string.chomp.should == "Name1\nName2"
    end
  end
end
