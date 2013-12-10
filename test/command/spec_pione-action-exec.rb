require 'pione/test-helper'

TestHelper.scope do |this|
  this::DIR = Location[File.dirname(__FILE__)] + ".." + "literate-action" + "data"

  describe Pione::Command::PioneActionExec do
    before do
      @cmd = Pione::Command::PioneActionExec
    end

    it "should execute action" do
      base = Location[Temppath.mkdir]
      args = [(this::DIR + "HelloWorld.md").path.to_s, "SayHello", "-d", base.path.to_s]
      TestHelper::Command.succeed(@cmd, args)
      (base + "message.txt").read.chomp.should == "Hello, world!"
    end
  end
end
