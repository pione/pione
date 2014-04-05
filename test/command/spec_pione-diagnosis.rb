require 'pione/test-helper'

describe Pione::Command::PioneDiagnosis do
  before do
    @cmd = Pione::Command::PioneDiagnosis
  end

  it "should fail because of no subcommands" do
    Rootage::ScenarioTest.fail(@cmd.new([]))
  end
end
