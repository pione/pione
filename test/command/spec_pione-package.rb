require 'pione/test-helper'

TestHelper.scope do |this|
  describe Pione::Command::PionePackage do
    before do
      @cmd = Pione::Command::PionePackage
    end

    it "should abort with no subcommands" do
      Rootage::ScenarioTest.fail(@cmd.new([]))
    end
  end
end

