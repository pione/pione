require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"

  describe Pione::Command::PioneAction do
    before do
      @cmd = Pione::Command::PioneAction
    end

    it "should execute action" do
      base = Location[Temppath.mkdir]
      args = [(this::DIR + "HelloWorld.md").path.to_s, "SayHello", "-d", base.path.to_s]
      TestHelper::Command.succeed(@cmd, args)
      (base + "message.txt").read.chomp.should == "Hello, world!"
    end

    it "should show action content" do
      args = [(this::DIR + "HelloWorld.md").path.to_s, "SayHello", "--show"]
      res = TestHelper::Command.succeed(@cmd, args)
      res.stdout.string.chomp.should == "echo \"Hello, world!\" > message.txt"
    end
  end
end
