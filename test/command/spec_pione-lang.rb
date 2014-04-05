require "pione/test-helper"

describe Pione::Command::PioneLang do
  before do
    @cmd = Pione::Command::PioneLang
  end

  it "should fail with no subcommands" do
    Rootage::ScenarioTest.fail(@cmd.new([]))
  end
end
