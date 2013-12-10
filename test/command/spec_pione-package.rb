require 'pione/test-helper'

TestHelper.scope do |this|
  describe Pione::Command::PionePackage do
    before do
      @cmd = Pione::Command::PionePackage
    end

    it "should abort with no subcommands" do
      TestHelper::Command.fail(@cmd, [])
    end
  end
end

