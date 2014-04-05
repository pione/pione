require "pione/test-helper"

describe Pione::Command::PioneConfig do
  before do
    @cmd = Pione::Command::PioneConfig
  end

  it "should fail with no subcommands" do
    Rootage::ScenarioTest.fail(@cmd.new([]))
  end
end
