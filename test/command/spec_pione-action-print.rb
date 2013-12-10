require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"

  describe Pione::Command::PioneActionPrint do
    before do
      @cmd = Pione::Command::PioneActionPrint
    end

    it "should print action contents" do
      args = [(this::DIR + "HelloWorld.md").path.to_s, "SayHello"]
      res = TestHelper::Command.succeed(@cmd, args)
      res.stdout.string.chomp.should == "echo \"Hello, world!\" > message.txt"
    end
  end
end
